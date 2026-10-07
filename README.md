[![Gem Version](https://badge.fury.io/rb/hive-ruby.svg)](https://badge.fury.io/rb/hive-ruby)
<!-- [![Inline docs](http://inch-ci.org/github/GalacticaActual/hive-ruby.svg?branch=master&style=shields)](http://inch-ci.org/github/GalacticaActual/hive-ruby) -->

# `hive-ruby`

Hive-ruby the Ruby API for Hive blockchain.

<!-- Full documentation: http://www.rubydoc.info/gems/hive-ruby -->

## `radiator` vs. `hive-ruby`

The `hive-ruby` gem was written from the ground up by `@inertia`, who is also the author of [`radiator`](https://github.com/inertia186/radiator).

> "I intend to continue work on `radiator` indefinitely. But in `radiator-0.5`, I intend to refactor `radiator` so that is uses `hive-ruby` as its core. This means that some features of `radiator` like Serialization will become redundant. I think it's still useful for radiator to do its own serialization because it reduces the number of API requests." - @inertia

`radiator` | `hive-ruby`
---------- | ------------
Has internal failover logic | Can have failover delegated externally
Passes `error` responses to the caller | Handles `error` responses and raises exceptions
Supports tx signing, does its own serialization | Also supports tx signing, but delegates serialization to `database_api.get_transaction_hex`, then deserializes to verify
All apis and methods are hardcoded | Asks `jsonrpc` what apis and methods are available from the node
(`radiator-0.4.x`) Only supports AppBase but relies on `condenser_api` | Only supports AppBase but does not rely on `condenser_api` **(WIP)**
Small list of helper methods for select ops (in addition to build your own transaction) | Complete implementation of helper methods for every op (in addition to build your own transaction)
Does not (yet) support `json-rpc-batch` requests | Supports `json-rpc-batch` requests

## Getting Started

The hive-ruby gem is compatible with Ruby 2.2.5 or later.

### Install the gem for your project

*(Assuming that [Ruby is installed](https://www.ruby-lang.org/en/downloads/) on your computer, as well as [RubyGems](http://rubygems.org/pages/download))*

To install the gem on your computer, run in shell:

```bash
gem install hive-ruby
```

... then add in your code:

```ruby
require 'hive'
```

To add the gem as a dependency to your project with [Bundler](http://bundler.io/), you can add this line in your Gemfile:

```ruby
gem 'hive-ruby', require: 'hive'
```

## Signing backend notes

`hive-ruby` prefers `libsecp256k1` through `rbsecp256k1` for signing and public-key recovery. If the extension cannot load or lacks recovery support, it automatically uses the included pure Ruby `ecdsa` dependency. Invalid keys, invalid signatures, and signing errors are reported; they do not switch backends.

For native acceleration, add the optional signer to your application's Gemfile:

```ruby
gem 'rbsecp256k1', '~> 6.0'
```

Without Bundler, install it with `gem install rbsecp256k1 -v '~> 6.0'`.  For Bundler applications, install and check recovery support:

```bash
bundle install
bundle exec ruby -rrbsecp256k1 -e 'puts Secp256k1.have_recovery?'
```

The command should print `true`. If the extension cannot build, remove the optional `rbsecp256k1` Gemfile entry and run `bundle install` to use the Ruby fallback. Bundler cannot ignore a failed build of an explicitly requested gem. To enable native signing on macOS, the bundled `libsecp256k1` build may need Automake/Autoconf tooling, e.g.:

```bash
brew install automake autoconf
bundle pristine rbsecp256k1
```

For downstream projects comparing deployment strategies:

* **Native path:** install `rbsecp256k1` as described above for speed and libsecp256k1's side-channel protections.
* **Pure Ruby fallback:** no extra setup is required. It generates fresh nonces with `SecureRandom`, produces low-S compact signatures, and supports compressed and uncompressed keys. The Ruby implementation is slower and does not provide constant-time execution.
* **Legacy fallback:** add `gem 'bitcoin-ruby', '0.0.20'` to your application's Gemfile, run `bundle install`, and set `HIVE_USE_LEGACY_BITCOIN_RUBY_SIGNER=1` to try the old signer path.  This is mainly useful for comparison or troubleshooting and may still fail on OpenSSL 3.
* **Fork strategy:** if a downstream project carries a patched `bitcoin-ruby` fork, test it behind the legacy fallback first.  If it proves reliable, compare its output against the default `rbsecp256k1` path before relying on it in production.

`bitcoin-ruby` is loaded only when legacy signing is explicitly selected. WIF decoding uses the pure Ruby `base58` gem and Ruby's SHA-256 digest support. You can inspect the selected signer with `Hive::CompactSigner.default.class`.

### JSON and runtime requirements

JSON also prefers native support when available, including extensions bundled with Ruby. Add `gem 'json', '~> 2.1'` to your application's Gemfile to use a current native gem. When native JSON cannot load, `json_pure` supplies parsing and generation. Inspect the selected parser with `JSON.parser`.

The fallback is pinned to `json_pure` 2.7.6: later releases are shims that require native JSON. It retains that version's JSON behavior, so float formatting and some malformed-input handling differ from newer native releases. The normal RPC payloads are covered by the same tests for both backends.

The runtime gem dependencies require no extension builds. Ruby's own standard-library extensions are still required: HTTPS uses OpenSSL, SHA-256 and RIPEMD-160 use Digest, and the pure JSON parser uses StringScanner. RIPEMD-160 does not depend on OpenSSL's enabled providers. Base58 and binary parsing already use pure Ruby packages.

To verify the fallback without native backends or development dependencies (offline RPC fixture; no broadcasts):

```bash
BUNDLE_GEMFILE=test/pure_ruby/Gemfile bundle install
BUNDLE_GEMFILE=test/pure_ruby/Gemfile bundle exec ruby test/pure_ruby/smoke.rb
```

## Examples

### Broadcast Vote

```ruby
params = {
  voter: voter,
  author: author,
  permlink: permlink,
  weight: weight
}

Hive::Broadcast.vote(wif: wif, params: params) do |result|
  puts result
end
```

<!-- *See: [Broadcast](https://www.rubydoc.info/gems/hive-ruby/Hive/Broadcast)* -->

### Streaming

The value passed to the block is an object, with the keys: `:type` and `:value`.

```ruby
stream = Hive::Stream.new

stream.operations do |op|
  puts "#{op.type}: #{op.value}"
end
```

To start a stream from a specific block number, pass it as an argument:

```ruby
stream = Hive::Stream.new

stream.operations(at_block_num: 9001) do |op|
  puts "#{op.type}: #{op.value}"
end
```

You can also grab the related transaction id and block number for each operation:

```ruby
stream = Hive::Stream.new

stream.operations do |op, trx_id, block_num|
  puts "#{block_num} :: #{trx_id}"
  puts "#{op.type}: #{op.value}"
end
```

To stream only certain operations:

```ruby
stream = Hive::Stream.new

stream.operations(types: :vote_operation) do |op|
  puts "#{op.type}: #{op.value}"
end
```

Or pass an array of certain operations:

```ruby
stream = Hive::Stream.new

stream.operations(types: [:comment_operation, :vote_operation]) do |op|
  puts "#{op.type}: #{op.value}"
end
```

Or (optionally) just pass the operation(s) you want as the only arguments.  This is semantic sugar for when you want specific types and take all of the defaults.

```ruby
stream = Hive::Stream.new

stream.operations(:vote_operation) do |op|
  puts "#{op.type}: #{op.value}"
end
```

To also include virtual operations:

```ruby
stream = Hive::Stream.new

stream.operations(include_virtual: true) do |op|
  puts "#{op.type}: #{op.value}"
end
```

### Multisig

You can use multisignature to broadcast an operation.

```ruby
params = {
  voter: voter,
  author: author,
  permlink: permlink,
  weight: weight
}

Hive::Broadcast.vote(wif: [wif1, wif2], params: params) do |result|
  puts result
end
```

In addition to signing with multiple `wif` private keys, it is possible to also export a partially signed transaction to have signing completed by someone else.

```ruby
builder = Hive::TransactionBuilder.new(wif: wif1)

builder.put(vote: {
  voter: voter,
  author: author,
  permlink: permlink,
  weight: weight
})

trx = builder.sign.to_json

File.open('trx.json', 'w') do |f|
  f.write(trx)
end
```

Then send the contents of `trx.json` to the other signing party so they can privately sign and broadcast the transaction.

```ruby
trx = open('trx.json').read
builder = Hive::TransactionBuilder.new(wif: wif2, trx: trx)
api = Hive::CondenserApi.new
trx = builder.transaction
api.broadcast_transaction_synchronous(trx)
```

### Get Accounts

```ruby
api = Hive::DatabaseApi.new

api.find_accounts(accounts: ['hiveio', 'alice']) do |result|
  puts result.accounts
end
```

<!-- *See: [Api](https://www.rubydoc.info/gems/hive-ruby/Hive/Api)* -->

### Reputation Formatter

```ruby
rep = Hive::Formatter.reputation(account.reputation)
puts rep
```

### Tests

* Clone the client repository into a directory of your choice:
  * `git clone https://gitlab.syncad.com/hive/hive-ruby.git`
* Navigate into the new folder
  * `cd hive-ruby`
* All tests can be invoked as follows:
  * `bundle exec rake test`
* To run `static` tests:
  * `bundle exec rake test:static`
* To run `broadcast` tests (broadcast is simulated, only `verify` is actually used):
  * `bundle exec rake test:broadcast`
* To run `threads` tests (which quickly verifies thread safety):
  * `bundle exec rake test:threads`
* To run `testnet` tests (which does actual broadcasts)
  * `TEST_NODE=https://testnet-api.openhive.network bundle exec rake test:testnet`

You can also run other tests that are not part of the above `test` execution:

* To run `block_range`, which streams blocks (using `json-rpc-batch`)
  * `bundle exec rake stream:block_range`


If you want to point to any node for tests, instead of letting the test suite pick the default, set the environment variable to `TEST_NODE`, e.g.:

```bash
$ TEST_NODE=https://testnet-api.openhive.network bundle exec rake test
```

## Contributions

Patches are welcome! Contributors are listed in the `hive-ruby.gemspec` file. Please run the tests (`rake test`) before opening a pull request and make sure that you are passing all of them. If you would like to contribute, but don't know what to work on, check the issues list.

## Issues

When you find issues, please report them!

## License

MIT
