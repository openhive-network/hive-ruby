require 'test_helper'

module Hive
  class AccountByKeyApiTest < Hive::Test
    def setup
      @api = Hive::AccountByKeyApi.new(url: TEST_NODE) rescue skip('account_by_key_api not supported')
      @jsonrpc = Jsonrpc.new(url: TEST_NODE)
      @methods = @jsonrpc.get_api_methods[@api.class.api_name]
    end
    
    def test_api_class_name
      assert_equal 'AccountByKeyApi', Hive::AccountByKeyApi::api_class_name
    end
    
    def test_inspect
      assert_equal "#<AccountByKeyApi [@chain=hive, @methods=<1 element>]>", @api.inspect
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
    
    def test_get_key_references
      vcr_cassette('account_by_key_api_get_key_references', record: :once) do
        options = {
          accounts: ['STM5jZtLoV8YbxCxr4imnbWn61zMB24wwonpnVhfXRmv7j6fk3dTH']
        }
        
        @api.get_key_references(options) do |result|
          assert_equal Hashie::Array, result.accounts.class
        end
      end
    end
  end
end
