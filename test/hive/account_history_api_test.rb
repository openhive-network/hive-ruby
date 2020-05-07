require 'test_helper'

module Hive
  # :nocov:
  class AccountHistoryApiTest < Hive::Test
    def setup
      @api = Hive::AccountHistoryApi.new(url: TEST_NODE) rescue skip('AccountHistoryApi is disabled.')
      @jsonrpc = Jsonrpc.new(url: TEST_NODE)
      @methods = @jsonrpc.get_api_methods[@api.class.api_name]
    end
    
    def test_api_class_name
      assert_equal 'AccountHistoryApi', Hive::AccountHistoryApi::api_class_name
    end
    
    def test_inspect
      assert_equal "#<AccountHistoryApi [@chain=hive, @methods=<4 elements>]>", @api.inspect
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
    
    def test_get_account_history
      vcr_cassette('account_history_api_get_account_history', record: :once) do
        options = {
          account: 'hiveio',
          start: 0,
          limit: 0
        }
        
        @api.get_account_history(options) do |result|
          assert_equal Hashie::Array, result.history.class
        end
      end
    end
    
    def test_get_ops_in_block
      vcr_cassette('account_history_api_get_ops_in_block', record: :once) do
        options = {
          block_num: 0,
          only_virtual: true
        }
        
        @api.get_ops_in_block(options) do |result|
          assert_equal Hashie::Array, result.ops.class
        end
      end
    end
    
    def test_get_transaction
      vcr_cassette('account_history_api_get_transaction', record: :once) do
        options = {
          id: 'ef73d8fadf17e2590c6d96efc1ca868edd7dd613',
        }
        
        @api.get_transaction(options) do |result|
          assert_equal Hashie::Array, result.history.class
        end
      end
    end
  end
  # :nocov:
end
