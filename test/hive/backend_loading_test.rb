require 'test_helper'
require 'open3'
require 'rbconfig'

module Hive
  class BackendLoadingTest < Hive::Test
    def test_native_backends_are_preferred
      run_child <<~RUBY
        require 'hive'
        abort 'JSON fallback selected with native available' unless JSON.parser.name == 'JSON::Ext::Parser'
        abort 'signer fallback selected with native available' unless Hive::CompactSigner.default.is_a?(Hive::CompactSigner::Rbsecp256k1)
      RUBY
    end

    def test_unavailable_native_extensions_use_pure_backends
      %w[json/ext json/ext/parser json/ext/generator].each do |missing|
        run_child <<~RUBY
          Kernel.prepend(Module.new do
            def require(path)
              if [#{missing.inspect}, 'rbsecp256k1'].include?(path)
                raise LoadError, "unavailable native extension: \#{path}"
              end
              super
            end
          end)
          require 'hive'
          require 'json'
          abort 'native parser selected' unless JSON.parser.name == 'JSON::Pure::Parser'
          abort 'native generator selected' unless JSON.generator.name == 'JSON::Pure::Generator'
          abort 'native signer selected' unless Hive::CompactSigner.default.is_a?(Hive::CompactSigner::PureRuby)
          object = {'text' => "Hive 🌍\\n\\u0000", 'large' => 18446744073709551615, 'values' => [nil, true, false, -1, 0.5]}
          [JSON.generate(object), object.to_json, JSON.pretty_generate(object)].each do |json|
            abort 'JSON roundtrip mismatch' unless JSON[json] == object
          end
          abort 'symbol keys changed' unless JSON[JSON.generate(a: 1)] == {'a' => 1}
          abort 'JSON scalar failed' unless JSON['123'] == 123
          begin
            JSON.parse('not JSON')
            abort 'malformed JSON accepted'
          rescue JSON::ParserError
          end
          begin
            JSON.parse('[' * 101 + '0' + ']' * 101)
            abort 'nesting limit lost'
          rescue JSON::NestingError
          end
          key = Hive::SigningKey.from_base58('L1qLfs5M5yBoRjAR25Sx4GxmnrAvGua5mS22LBrJFsL6zknQrNjs')
          signer = Hive::CompactSigner.default
          signature = signer.sign_compact('x' * 32, key.private_key_hex, key.pub, key.compressed)
          abort 'signature recovery mismatch' unless signer.recover_compact('x' * 32, signature) == key.pub
        RUBY
      end
    end

  private
    def run_child(script)
      stdout, stderr, status = Open3.capture3(RbConfig.ruby, '-Ilib', '-e', script)
      assert status.success?, "#{stdout}\n#{stderr}"
    end
  end
end
