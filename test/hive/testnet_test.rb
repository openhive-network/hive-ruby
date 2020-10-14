require 'test_helper'

module Hive
  class TestnetTest < Hive::Test
    def setup
      @api = Api.new(url: TEST_NODE)
      @jsonrpc = Jsonrpc.new(url: TEST_NODE)
      @methods = @jsonrpc.get_api_methods[@api.class.api_name]
      
      @api.get_config do |result|
        unless result['IS_TEST_NET']
          skip "Skipped, because #{TEST_NODE} is not testnet.  Instead, found chain id: #{result['HIVE_CHAIN_ID']}"
        end
      end
    end
    
    def test_get_dynamic_global_properties
      @api.get_dynamic_global_properties do |properties|
        assert '0.000 TBD', properties.confidential_hbd_supply
        assert '0.000 TESTS', properties.confidential_supply
        assert '0.000 TBD', properties.current_hbd_supply
        assert '0.000000 VESTS', properties.pending_rewarded_vesting_shares
        assert '0.000 TESTS', properties.pending_rewarded_vesting_hive
        assert '0.000 TESTS', properties.total_reward_fund_hive
      end
    end
  end
end
