require 'test_helper'

module Hive
  class RcApiTest < Hive::Test
    def setup
      @api = Hive::RcApi.new(url: TEST_NODE) rescue skip('rc_api not supported')
      @jsonrpc = Jsonrpc.new(url: TEST_NODE)
      vcr_cassette('jsonrpc_get_methods', record: :once) do
        @methods = @jsonrpc.get_api_methods[@api.class.api_name]
      end
    end
    
    def test_api_class_name
      assert_equal 'RcApi', Hive::RcApi::api_class_name
    end
    
    def test_inspect
      assert_match(/^#<RcApi \[@chain=hive, @methods=<\d+ elements>\]>$/, @api.inspect)
    end
    
    def test_method_missing
      assert_raises NoMethodError do
        @api.bogus
      end
    end
    
    def test_all_respond_to
      @methods.each do |key|
        skip 'get_rc_operation_stats is not exposed by the current node' if key.to_sym == :get_rc_operation_stats
        assert @api.respond_to?(key), "expect rpc respond to #{key}"
      end
    end
    
    def test_find_rc_accounts
      vcr_cassette('rc_api_find_rc_accounts', record: :once) do
        options = {
          accounts: ['hive']
        }
        
        @api.find_rc_accounts(options) do |result|
          assert_equal Hashie::Array, result.rc_accounts.class
        end
      end
    end
    
    def test_get_resource_params
      vcr_cassette('rc_api_get_resource_params', record: :once) do
        @api.get_resource_params do |result|
          assert_equal Hashie::Mash, result.class
        end
      end
    end
    
    def test_get_resource_pool
      vcr_cassette('rc_api_get_resource_pool', record: :once) do
        @api.get_resource_pool do |result|
          assert_equal Hashie::Mash, result.class
        end
      end
    end
  end
end
