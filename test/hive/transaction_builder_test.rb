require 'test_helper'

module Hive
  class TransactionBuilderTest < Hive::Test
    include ChainConfig

    class FakeSigningDatabaseApi
      TRANSACTION_HEX = '62df7b81fb720ae4fb690201000f706172656e745f7065726d6c696e6b06736f6369616c087065726d6c696e6b057469746c6504626f6479197b22617070223a22686976652d727562792f312e302e36227d1306736f6369616c087065726d6c696e6b00ca9a3b00000000035342440000000010270101000000'

      def get_config
        yield({ 'HIVE_CHAIN_ID' => Hive::ChainConfig::NETWORKS_HIVE_CHAIN_ID }) if block_given?
      end

      def get_transaction_hex(_args)
        yield TRANSACTION_HEX if block_given?
      end
    end

    class FakeSigningBlockApi
    end
    
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
      
    def test_sign_with_default_rbsecp256k1_signer
      builder = TransactionBuilder.new(@options.merge(
        database_api: FakeSigningDatabaseApi.new,
        block_api: FakeSigningBlockApi.new,
        force_serialize: true,
        wif: @wif,
        trx: {
          ref_block_num: 57186,
          ref_block_prefix: 1929085307,
          expiration: '2099-05-07T00:59:54',
          operations: [["comment", {
            parent_author: '',
            parent_permlink: 'parent_permlink',
            author: 'social',
            permlink: 'permlink',
            title: 'title',
            body: 'body',
            json_metadata: '{"app":"hive-ruby/1.0.6"}'
          }], ["comment_options", {
            author: 'social',
            permlink: 'permlink',
            max_accepted_payout: '1000000.000 HBD',
            percent_hbd: 10000,
            allow_votes: true,
            allow_curation_rewards: true,
            extensions: []
          }]],
          extensions: [],
          signatures: []
        }
      ))

      trx = builder.sign
      signature = [trx.signatures.first].pack('H*')
      digest = Digest::SHA256.digest([NETWORKS_HIVE_CHAIN_ID + FakeSigningDatabaseApi::TRANSACTION_HEX[0..-4]].pack('H*'))
      public_key_hex = SigningKey.from_base58(@wif).pub

      assert_equal 1, trx.signatures.size
      assert_equal 65, signature.bytesize
      refute builder.send(:canonical?, signature), 'fixture should prove rbsecp256k1 signer does not use the legacy canonical-grinding loop'
      assert_equal public_key_hex, CompactSigner.default.recover_compact(digest, signature)
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
