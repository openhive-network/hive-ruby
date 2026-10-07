# Run with plain Ruby after installing the built gem, without -Ilib or Bundler.
require 'hive'

raise 'Expected an installed Hive gem' unless Gem.loaded_specs.key?('hive-ruby')
raise 'Expected native JSON parser' unless JSON.parser.name == 'JSON::Ext::Parser'
raise 'Expected native JSON generator' unless JSON.generator.name == 'JSON::Ext::Generator'
raise 'JSON Ruby files and extension versions differ' unless JSON::VERSION == Gem.loaded_specs.fetch('json').version.to_s
raise 'Expected native signer' unless Hive::CompactSigner.default.is_a?(Hive::CompactSigner::Rbsecp256k1)

object = {'text' => "Hive 🌍\n", 'values' => [nil, true, false, 18446744073709551615, 0.5]}
raise 'JSON roundtrip failed' unless JSON.parse(JSON.generate(object)) == object

puts 'Installed gem: native JSON loading, roundtrip and signer selection passed.'
