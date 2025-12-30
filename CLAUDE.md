# hive-ruby

## Project Overview

Ruby API client library for the Hive blockchain. Complete implementation supporting transaction broadcasting, streaming, and all blockchain operations. Version 1.0.5 (HF27 compatible).

Key features:
- Full Ruby API for Hive blockchain interaction
- Transaction broadcasting with multisignature support
- Streaming for blocks, transactions, and operations (including virtual ops)
- JSON-RPC batch request support
- Thread-safe HTTP client for concurrent requests
- Dynamic API discovery from Hive nodes

## Tech Stack

- **Ruby**: 2.2.5+ (tested with 2.7+ and 3.0+)
- **Core Dependencies**:
  - `json` (~> 2.1) - JSON serialization
  - `logging` (~> 2.2) - Logging framework
  - `hashie` (>= 3.5) - Hash manipulation
  - `bitcoin-ruby` (0.0.20) - Cryptographic signing
  - `ffi` (~> 1.9) - Foreign Function Interface
  - `bindata` (~> 2.4) - Binary data parsing
  - `base58` (~> 0.2) - Base58 encoding
- **Testing**: minitest, webmock, vcr, simplecov
- **Documentation**: yard

## Directory Structure

```
lib/hive/
├── hive.rb              # Main entry, requires all modules
├── version.rb           # Version constant
├── api.rb               # Base API with dynamic namespace handling
├── jsonrpc.rb           # JSON-RPC client wrapper
├── broadcast.rb         # Transaction broadcasting (largest file)
├── transaction_builder.rb # Transaction creation and signing
├── stream.rb            # Streaming blocks/transactions/operations
├── operation.rb         # Operation type definitions + virtual ops
├── operation/           # Individual operation classes (35 files)
├── mixins/              # Shared functionality (jsonable, serializable, retriable)
├── rpc/                 # HTTP/RPC client implementations
└── type/                # Custom type classes (amount, etc.)

test/
├── test_helper.rb       # Test configuration
├── hive/                # Test files (20+ files)
└── fixtures/vcr_cassettes/  # Recorded HTTP interactions
```

## Development Commands

```bash
# Install dependencies
bundle install

# Run tests
bundle exec rake test              # All tests (default)
bundle exec rake test:static       # Static tests (read-only, mocked)
bundle exec rake test:broadcast    # Broadcast tests (signing validation)
bundle exec rake test:testnet      # Real testnet broadcasts
bundle exec rake test:threads      # Thread safety verification

# Streaming tasks
bundle exec rake stream:block_range
bundle exec rake stream:op_range
bundle exec rake stream:vop_range

# Utilities
bundle exec rake console           # IRB with hive loaded
bundle exec rake yard              # Generate documentation
bundle exec rake clean:vcr         # Remove VCR cassettes
bundle exec rake show:apis         # Display available APIs
bundle exec rake show:methods[api] # Show methods for specific API
```

**Environment Variables**:
- `TEST_NODE=<url>` - Custom node (default: mainnet)
- `VCR_RECORD_MODE=<mode>` - VCR recording mode
- `TEST_ACCOUNT_NAME=<name>` - Test account (default: `social`)
- `TEST_WIF=<key>` - Test account private key
- `HIVE_CHAIN_ID=<id>` - Override chain ID

## Key Files

- `lib/hive.rb` - Main entry point
- `lib/hive/api.rb` - Base API class with dynamic method generation
- `lib/hive/broadcast.rb` - High-level operation helpers
- `lib/hive/transaction_builder.rb` - Transaction creation/signing
- `lib/hive/stream.rb` - Block/transaction streaming
- `lib/hive/operation.rb` - Operation type definitions
- `hive-ruby.gemspec` - Gem specification
- `Rakefile` - Task definitions
- `test/test_helper.rb` - Test configuration

## Coding Conventions

- All code in `module Hive` namespace
- Class names: CamelCase (`TransactionBuilder`, `DatabaseApi`)
- Method names: snake_case
- Constants: SCREAMING_SNAKE_CASE
- 2-space indentation
- Symbol-based hash keys for internal APIs
- Block-based callbacks for responses: `api.method { |result| ... }`

**Error Handling**:
- Custom exception hierarchy from `BaseError`
- Specific types: `RemoteDatabaseLockError`, `RemoteServerError`, `PluginNotEnabledError`

**Testing**:
- Minitest with VCR for HTTP recording/replay
- Cassettes in `test/fixtures/vcr_cassettes/`
- Thread safety tests via `minitest-hell`

## CI/CD Notes

**GitLab CI** (`.gitlab-ci.yml`):
- Image: `ruby:2.6.1-alpine`
- Single stage: `pages` (documentation)
- Generates YARD docs, publishes to GitLab Pages
- Only runs on `master` branch
- Caches `vendor/` directory

**No automated test pipeline** - tests run locally. CI only handles documentation deployment.

## API Usage Examples

```ruby
# Basic API call
api = Hive::DatabaseApi.new
api.get_dynamic_global_properties { |result| puts result }

# Streaming
stream = Hive::Stream.new
stream.blocks { |block| process(block) }
stream.operations(:vote) { |op| handle_vote(op) }

# Broadcasting
Hive::Broadcast.vote(wif: 'WIF_KEY', voter: 'user', author: 'author', permlink: 'post', weight: 10000)
```

## Notes

- Uses `const_missing` for dynamic API class generation
- 60+ operation types supported
- VCR cassettes excluded from gem package but committed to repo
- Thread-safe by default (`ThreadSafeHttpClient`)
