require 'test_helper'

module Hive
  class BridgeTest < Hive::Test
    def setup
      @api = Hive::Bridge.new(url: TEST_NODE)
      @jsonrpc = Jsonrpc.new(url: TEST_NODE)
      @methods = @jsonrpc.get_api_methods[@api.class.api_name] rescue Fallback::API_METHODS[:bridge]
    end
    
    def test_api_class_name
      assert_equal 'Bridge', Hive::Bridge::api_class_name
    end
    
    def test_inspect
      assert_equal "#<Bridge [@chain=hive, @methods=<5 elements>]>", @api.inspect
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
    
    def test_account_notifications
      vcr_cassette('bridge_account_notifications', record: :once) do
        options = {
          account: 'alice',
          limit: 10
        }
        
        @api.account_notifications(options) do |result|
          assert_equal Hashie::Array, result.class
        end
      end
    end
    
    def test_get_community
      vcr_cassette('bridge_get_community', record: :once) do
        options = {
          name: 'hive-100525',
          observer: 'alice'
        }
        
        @api.get_community(options) do |result|
          assert_equal Hashie::Mash, result.class
        end
      end
    end
    
    def test_get_ranked_posts
      vcr_cassette('bridge_get_ranked_posts', record: :once) do
        options = {
          sort: 'trending',
          tag: '',
          observer: 'alice'
        }
        
        @api.get_ranked_posts(options) do |result|
          assert_equal Hashie::Array, result.class
        end
      end
    end
    
    def test_list_all_subscriptions
      vcr_cassette('bridge_list_all_subscriptions', record: :once) do
        options = {
          account: 'alice'
        }
        
        @api.list_all_subscriptions(options) do |result|
          assert_equal Hashie::Array, result.class
        end
      end
    end
    
    def test_list_community_roles
      vcr_cassette('bridge_list_community_roles', record: :once) do
        options = {
          community: 'hive-100525'
        }
        
        @api.list_community_roles(options) do |result|
          assert_equal Hashie::Array, result.class
        end
      end
    end
  end
end
