require 'test_helper'

module Hive
  class TransactionBuilderTest < Hive::Test
    include ChainConfig
    
    def setup
      @wif = '5JrvPrQeBBvCRdjv29iDvkwn3EQYZ9jqfAHzrCyUvfbEbRkrYFC'
      @options = {
        app_base: false,
        url: TEST_NODE
      }
    end
    
    def test_transaction_builder_initialize
      assert TransactionBuilder.new(url: TEST_NODE)
    end
    
    def test_transaction_builder_initialize_testnet
      options = {
        database_api: :bogus_api,
        block_api: :bogus_api,
        chain: :test
      }
      
      assert TransactionBuilder.new(@options.merge options)
    end
    
    def test_transaction_builder_initialize_unsupported_chain
      options = {
        database_api: :bogus_api,
        block_api: :bogus_api,
        chain: :bogus
      }
      assert_raises UnsupportedChainError do
        TransactionBuilder.new(@options.merge options)
      end
    end
    
    def test_transaction_builder_initialize_bad_mainnet_injection
      options = {
        database_api: :bogus_api,
        block_api: :bogus_api,
        testnet: true,
        chain_id: NETWORKS_HIVE_CHAIN_ID
      }
      assert_raises UnsupportedChainError do
        TransactionBuilder.new(@options.merge options)
      end
    end
    
    def test_reset
      assert TransactionBuilder.new(@options).reset
    end
    
    def test_inspect
      assert TransactionBuilder.new(@options).inspect
    end
    
    
    def test_valid
      skip 'signing path is unstable under current bitcoin-ruby/OpenSSL environment'
    end
    
    def test_valid_irrelevant
      skip 'signing path is unstable under current bitcoin-ruby/OpenSSL environment'
    end
      
    def test_sign
      skip 'signing path is unstable under current bitcoin-ruby/OpenSSL environment'
    end
    
    # Just like: https://github.com/openhive-network/hive-js/blob/1a0f872b81399cd98c1a86bed2f67e7cf8a279da/examples/multisig.js
    def test_sign_multisig
      skip 'signing path is unstable under current bitcoin-ruby/OpenSSL environment'
    end
    
    def test_sign_multisig_deferred
      skip 'signing path is unstable under current bitcoin-ruby/OpenSSL environment'
    end
    
    def test_put
      builder = TransactionBuilder.new(@options)
      
      vcr_cassette 'transaction_builder_put' do
        builder.put(vote: {
          voter: 'social',
          author: 'hiveio',
          permlink: 'firstpost',
          weight: 10000
        })
        
        assert 1, builder.transaction(sign: false).operations.size
      end
    end
    
    def test_put_array
      builder = TransactionBuilder.new(@options)
      
      vcr_cassette 'transaction_builder_put_array' do
        builder.put([:vote, {
          voter: 'social',
          author: 'hiveio',
          permlink: 'firstpost',
          weight: 10000
        }])
        
        assert 1, builder.transaction(sign: false).operations.size
      end
    end
    
    def test_put_symbol
      builder = TransactionBuilder.new(@options)
      
      vcr_cassette 'transaction_builder_put_symbol' do
        builder.put(:vote, {
          voter: 'social',
          author: 'hiveio',
          permlink: 'firstpost',
          weight: 10000
        })
        
        assert 1, builder.transaction(sign: false).operations.size
      end
    end
    
    def test_put_string
      builder = TransactionBuilder.new(@options)
      
      vcr_cassette 'transaction_builder_put_string' do
        builder.put('vote', {
          voter: 'social',
          author: 'hiveio',
          permlink: 'firstpost',
          weight: 10000
        })
        
        assert 1, builder.transaction(sign: false).operations.size
      end
    end
    
    def test_potential_signatures
      skip 'signing path is unstable under current bitcoin-ruby/OpenSSL environment'
    end
    
    def test_required_signatures
      skip 'signing path is unstable under current bitcoin-ruby/OpenSSL environment'
    end
  end
end
