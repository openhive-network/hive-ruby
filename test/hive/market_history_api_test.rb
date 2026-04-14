require 'test_helper'

module Hive
  class MarketHistoryApiTest < Hive::Test
    def setup
      @api = Hive::MarketHistoryApi.new(url: TEST_NODE) rescue skip('market_history_api not supported')
      @jsonrpc = Jsonrpc.new(url: TEST_NODE)
      vcr_cassette('jsonrpc_get_methods', record: :once) do
        @methods = @jsonrpc.get_api_methods[@api.class.api_name]
      end
    end
    
    def test_api_class_name
      assert_equal 'MarketHistoryApi', Hive::MarketHistoryApi::api_class_name
    end
    
    def test_inspect
      assert_equal "#<MarketHistoryApi [@chain=hive, @methods=<7 elements>]>", @api.inspect
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
    
    def test_get_market_history
      vcr_cassette('market_history_api_get_market_history', record: :once) do
        options = {
          bucket_seconds: 0,
          start: '1970-01-01T00:00:00',
          end: '1970-01-01T00:00:00'
        }
        
        @api.get_market_history(options) do |result|
          assert_equal Hashie::Array, result.buckets.class
        end
      end
    end
    
    def test_get_market_history_buckets
      vcr_cassette('market_history_api_get_market_history_buckets', record: :once) do
        @api.get_market_history_buckets do |result|
          assert_equal Hashie::Array, result.bucket_sizes.class
        end
      end
    end
    
    def test_get_order_book
      vcr_cassette('market_history_api_get_order_book', record: :once) do
        @api.get_order_book(limit: 0) do |result|
          assert_equal Hashie::Mash, result.class
        end
      end
    end
    
    def test_get_recent_trades
      vcr_cassette('market_history_api_get_recent_trades', record: :once) do
        @api.get_recent_trades(limit: 0) do |result|
          assert_equal Hashie::Array, result.trades.class
        end
      end
    end
    
    def test_get_ticker
      vcr_cassette('market_history_api_get_ticker', record: :once) do
        @api.get_ticker do |result|
          assert_equal Hashie::Mash, result.class
        end
      end
    end
    
    def test_get_trade_history
      vcr_cassette('market_history_api_get_trade_history', record: :once) do
        options = {
          start: '1970-01-01T00:00:00',
          end: '1970-01-01T00:00:00',
          limit: 0
        }
        
        @api.get_trade_history(options) do |result|
          assert_equal Hashie::Array, result.trades.class
        end
      end
    end
    
    def test_get_volume
      vcr_cassette('market_history_api_get_volume', record: :once) do
        @api.get_volume do |result|
          assert_equal Hashie::Mash, result.class
        end
      end
    end
  end
end
