# Offline CI subset: no cassettes, node requests, or legacy signing skips.
ENV['SKIP_OPENSSL3_SIGNING'] = '0'
ENV['RERAISE_HIVE_BASE_ERRORS'] = '1'
require 'test_helper'

WebMock.disable_net_connect!
VCR.configure do |config|
  config.before_http_request(:real?) { raise 'Backend tests must not make network requests' }
end

ARGV.concat(['--name', '/SigningKeyTest|CompactSignerTest|BackendLoadingTest|MarshalIntegerTest|test_sign_with_default_rbsecp256k1_signer|test_sign_with_pure_ruby_fallback|test_sign_reports_missing_optional_legacy_dependency/'])

require_relative 'hive/signing_key_test'
require_relative 'hive/compact_signer_test'
require_relative 'hive/backend_loading_test'
require_relative 'hive/marshal_integer_test'
require_relative 'hive/transaction_builder_test'
