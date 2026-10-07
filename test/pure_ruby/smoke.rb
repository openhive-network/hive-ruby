# Run with BUNDLE_GEMFILE=test/pure_ruby/Gemfile bundle exec ruby test/pure_ruby/smoke.rb
# This bundle exposes only runtime dependencies; all requests stay in-process.
Kernel.prepend(Module.new do
  def require(path)
    if path.start_with?('json/ext') || path == 'rbsecp256k1'
      raise LoadError, "Native backend disabled for this smoke test: #{path}"
    end
    super
  end
end)
require 'hive'

native = Gem.loaded_specs.values.reject(&:default_gem?).reject { |spec| spec.extensions.empty? }
raise "Native runtime dependencies: #{native.map(&:name)}" unless native.empty?
raise 'Native JSON gem activated' if Gem.loaded_specs.key?('json')
raise 'Native signer activated' if Gem.loaded_specs.key?('rbsecp256k1')
raise 'Expected pure JSON parser' unless JSON.parser.name == 'JSON::Pure::Parser'
raise 'Expected pure JSON generator' unless JSON.generator.name == 'JSON::Pure::Generator'

class FixtureRpc < Hive::RPC::ThreadSafeHttpClient
  def http_request(request)
    input = JSON.parse(request.body)
    raise 'Unexpected RPC' unless input['method'] == 'condenser_api.get_dynamic_global_properties'
    Struct.new(:code, :body).new('200', JSON.generate(
      jsonrpc: '2.0', id: input['id'], result: {head_block_number: 110000000}
    ))
  end
end

response = FixtureRpc.new.rpc_execute('condenser_api', 'get_dynamic_global_properties', {})
raise 'RPC roundtrip failed' unless response.result.head_block_number == 110000000

signer = Hive::CompactSigner.default
raise 'Expected pure signer' unless signer.is_a?(Hive::CompactSigner::PureRuby)
key = Hive::SigningKey.from_base58('L1qLfs5M5yBoRjAR25Sx4GxmnrAvGua5mS22LBrJFsL6zknQrNjs')
public_key = '02604738fa008878e9e3a4853307ad41524234dd9e3d48ff559d4b04094c42800f'
raise 'Key derivation failed' unless key.pub == public_key
digest = Digest::SHA256.digest('Hive fallback smoke test')
signature = signer.sign_compact(digest, key.private_key_hex, key.pub, key.compressed)
raise 'Signature recovery failed' unless signer.recover_compact(digest, signature) == public_key
raise 'Signature is not low-S' unless signature.byteslice(33, 32).unpack1('H*').to_i(16) <= Hive::CompactSigner::ORDER / 2
raise 'RIPEMD-160 failed' unless Digest::RMD160.hexdigest('abc') == '8eb208f7e05d987a9b044a8e98c6b087f15a0bfc'

puts 'Pure Ruby runtime: RPC, JSON, WIF, key derivation, signing, recovery and digests passed.'
