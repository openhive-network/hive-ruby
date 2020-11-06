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
    
    def test_get_account_history_with_op_mask
      vcr_cassette('account_history_api_get_account_history_with_op_mask', record: :once) do
        # We're looking specifically for comment_operation, therefore, for the
        # first 64 operation types (as defined in protocol/operations.hpp), we set
        # the corresponding bit in operation_filter_low; for the higher-numbered
        # operations, set the bit in operation_filter_high (pretending
        # operation_filter is a 128-bit bitmask composed of
        # {operation_filter_high, operation_filter_low})
        # 
        # Note, we don't really use the operation_filter_high because
        # comment_operation is the second flag.  In fact, operation_filter_high
        # could even be nil, if we wanted.
        # 
        # https://gitlab.syncad.com/hive/hive/-/blob/master/libraries/protocol/include/hive/protocol/operations.hpp
        
        operation_mask = 0x02 # comment_operation
        operation_filter_low = operation_mask & 0xFFFFFFFF
        operation_filter_high = (operation_mask & 0xFFFFFFFF00000000) >> 32

        options = {
          account: 'hiveio',
          start: 0,
          limit: 0,
          include_reversible: true,
          operation_filter_low: operation_filter_low,
          operation_filter_high: operation_filter_high
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
          assert_equal Hashie::Mash, result.class
        end
      end
    end
  end
  # :nocov:
end
