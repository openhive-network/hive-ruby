require 'test_helper'

module Hive
  class NetworkBroadcastApiTest < Hive::Test
    def setup
      @api = Hive::NetworkBroadcastApi.new(url: TEST_NODE) rescue skip('network_broadcast_api not supported')
      @jsonrpc = Jsonrpc.new(url: TEST_NODE)
      vcr_cassette('jsonrpc_get_methods', record: :once) do
        @methods = @jsonrpc.get_api_methods[@api.class.api_name]
      end
    end
    def test_api_class_name
      assert_equal 'NetworkBroadcastApi', Hive::NetworkBroadcastApi::api_class_name
    end
    
    def test_inspect
      assert_equal "#<NetworkBroadcastApi [@chain=hive, @methods=<1 element>]>", @api.inspect
    end
    
    def test_method_missing
      assert_raises NoMethodError do
        @api.bogus
      end
    end
    
    def test_all_respond_to
      @methods.each do |key|
        assert @api.respond_to?(key), "expect rpc respond to #{key}"
      end
    end
    
    def test_broadcast_transaction
      vcr_cassette('broadcast_transaction') do
        options = {
          trx: {
            ref_block_num: 0,
            ref_block_prefix: 0,
            expiration: "1970-01-01T00:00:00",
            operations: [],
            extensions: [],
            signatures: []
          },
          max_block_age: -1
        }
        
        assert_raises TransactionExpiredError do
          @api.broadcast_transaction(options)
        end
      end
    end
  end
end
