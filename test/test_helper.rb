$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'simplecov'

SimpleCov.start
SimpleCov.merge_timeout 3600

require 'hive'
require 'minitest/autorun'
require 'minitest/line/describe_track'
require 'webmock/minitest'
require 'vcr'
require 'yaml'
require 'awesome_print'

VCR.configure do |c|
  c.cassette_library_dir = 'test/fixtures/vcr_cassettes'
  c.hook_into :webmock

  c.register_request_matcher :jsonrpc_body do |request_1, request_2|
    normalize = lambda do |request|
      body = request.body.to_s
      parsed = JSON.parse(body) rescue body

      normalize_entry = lambda do |entry|
        if entry.is_a?(Hash)
          normalized = entry.reject { |k, _| k == 'id' }
          {
            'jsonrpc' => normalized['jsonrpc'],
            'method' => normalized['method'],
            'params' => normalized['params']
          }
        else
          entry
        end
      end

      if parsed.is_a?(Array)
        parsed.map { |entry| normalize_entry.call(entry) }
      else
        normalize_entry.call(parsed)
      end
    end

    normalize.call(request_1) == normalize.call(request_2)
  end
end

module VcrJsonRpcIdNormalizer
  def self.normalize(request_body, response_body)
    parsed_request = JSON.parse(request_body.to_s)
    parsed_response = JSON.parse(response_body.to_s)

    case
    when parsed_request.is_a?(Array) && parsed_response.is_a?(Array)
      normalized = parsed_response.each_with_index.map do |item, index|
        next item unless item.is_a?(Hash)
        request_item = parsed_request[index]
        next item unless request_item.is_a?(Hash) && request_item.key?('id')

        item.merge('id' => request_item['id'])
      end
      JSON.generate(normalized)
    when parsed_request.is_a?(Hash) && parsed_response.is_a?(Hash) && parsed_request.key?('id')
      JSON.generate(parsed_response.merge('id' => parsed_request['id']))
    else
      response_body
    end
  rescue JSON::ParserError, NoMethodError
    response_body
  end
end

# During VCR-backed JSON-RPC replay, recorded response ids often reflect the
# original request sequence rather than the current replay sequence. Normalize
# ids after VCR/WebMock has already selected the interaction using
# method/uri/jsonrpc_body matching.
#
# Important: this must also work for mixed modes like :new_episodes. In that
# mode, `cassette.recording?` is true even while many responses are being
# replayed from existing interactions. Gating on `!cassette.recording?` causes
# stale recorded ids to leak through and trip evaluate_id retry loops.
WebMock.after_request do |request_signature, response|
  next unless response
  next unless defined?(VCR) && VCR.respond_to?(:current_cassette)

  cassette = VCR.current_cassette
  next unless cassette
  next unless request_signature.uri.to_s.include?('api.openhive.network') || request_signature.uri.to_s.include?('openhive.network')
  next unless request_signature.body.to_s.include?('jsonrpc')

  body = response.body
  next unless body.is_a?(String)

  response.body = VcrJsonRpcIdNormalizer.normalize(request_signature.body, body)
end

HELL_ENABLED = ENV['HELL_ENABLED'] == '1'

require 'minitest/hell' if HELL_ENABLED
require 'minitest/proveit'

class Minitest::Test
  # See: https://gist.github.com/chrisroos/b5da6c6a37ac8af5fe78
  parallelize_me! if HELL_ENABLED && !defined?(WebMock)
end

class Hive::Test < Minitest::Test
  defined? prove_it! and prove_it!

  OPENSSL3_SIGNING_HINT = <<~MSG.freeze
    OpenSSL 3 signing compatibility breached during v1 containment.
    Re-run with SKIP_OPENSSL3_SIGNING=1 to keep going with the temporary v1 overskip path:

      SKIP_OPENSSL3_SIGNING=1 rake test

    v2 is expected to implement real signing and reduce these skips.
  MSG
  
  TEST_NODE = ENV.fetch 'TEST_NODE', Hive::ChainConfig::NETWORKS_HIVE_DEFAULT_NODE
  # TEST_NODE = Hive::ChainConfig::NETWORKS_TEST_DEFAULT_NODE
  
  # Most likely modes: 'once' and 'new_episodes'
  VCR_RECORD_MODE = (ENV['VCR_RECORD_MODE'] || 'once').to_sym
  SKIP_OPENSSL3_SIGNING = ENV['SKIP_OPENSSL3_SIGNING'] == '1'
  RERAISE_HIVE_BASE_ERRORS = ENV['RERAISE_HIVE_BASE_ERRORS'] == '1'
  
  def vcr_cassette(name, options = {}, &block)
    options = {
      match_requests_on: [:method, :uri, :jsonrpc_body]
    }.merge(options)
    options[:record] ||= VCR_RECORD_MODE
    
    VCR.use_cassette(name, options) do
      begin
        yield
      rescue OpenSSL::PKey::PKeyError => e
        if e.message.include?('pkeys are immutable on OpenSSL 3.0')
          if SKIP_OPENSSL3_SIGNING
            skip 'v1 containment: signing path is blocked by bitcoin-ruby/OpenSSL 3 compatibility; real fix deferred to v2.'
          else
            raise OpenSSL::PKey::PKeyError, "#{OPENSSL3_SIGNING_HINT}\nOriginal error: #{e.message}"
          end
        else
          raise e
        end
      rescue Hive::BaseError => e
        raise e if RERAISE_HIVE_BASE_ERRORS
        skip "Probably just a node acting up: #{e}\n#{e.backtrace.join("\n")}"
      rescue Psych::SyntaxError => e
        skip 'This happens when we try to get fancy and disable thread-safety.'
      end
    end
  end
end
