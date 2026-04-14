require 'test_helper'

module Hive
  class BridgeTest < Hive::Test
    def setup
      @api = Hive::Bridge.new(url: TEST_NODE)
      @condenser_api = Hive::CondenserApi.new(url: TEST_NODE)
      @jsonrpc = Jsonrpc.new(url: TEST_NODE)

      begin
        vcr_cassette('jsonrpc_get_methods', record: :once) do
          @methods = @jsonrpc.get_api_methods[@api.class.api_name]
        end
      rescue
        @methods = Fallback::API_METHODS[:bridge]
      end

      skip 'bridge is not exposed by the current node' if @methods.nil?
    end
    
    def test_api_class_name
      assert_equal 'Bridge', Hive::Bridge::api_class_name
    end
    
    def test_inspect
      assert_equal "#<Bridge [@chain=hive, @methods=<19 elements>]>", @api.inspect
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
    
    def test_normalize_post
      vcr_cassette('bridge_normalize_post', record: :once) do
        author = 'inertia'
        permlink = 'kinda-spooky'
        post = @condenser_api.get_content(author, permlink).result
        options = {
          post: post
        }
        
        @api.normalize_post(options) do |result|
          assert_equal Hashie::Mash, result.class
          assert_equal author, result.author
          assert_equal permlink, result.permlink
          
          known_normalization_fields = %w(post_id updated is_paidout payout_at payout
            author_payout_value stats blacklists reblogs)
            
          assert_equal known_normalization_fields.sort, (result.keys - post.keys).sort, 'found unknown fields added by hivemind normalization'
        end
      end
    end
    
    def test_get_post_header
      vcr_cassette('bridge_get_post_header', record: :once) do
        author = 'inertia'
        permlink = 'kinda-spooky'
        post = @condenser_api.get_content(author, permlink).result
        options = {
          author: author,
          permlink: permlink
        }
        
        @api.get_post_header(options) do |result|
          assert_equal Hashie::Mash, result.class
          assert_equal author, result.author
          assert_equal permlink, result.permlink
          assert_equal [], result.keys - post.keys
        end
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
    
    def test_get_discussion
      vcr_cassette('bridge_get_discussion', record: :once) do
        options = {
          author: 'inertia',
          permlink: 'kinda-spooky'
        }
        
        @api.get_discussion(options) do |result|
          assert_equal Hashie::Mash, result.class
        end
      end
    end
    
    def test_get_post
      vcr_cassette('bridge_get_post', record: :once) do
        options = {
          author: 'inertia',
          permlink: 'kinda-spooky',
          observer: 'alice'
        }
        
        @api.get_post(options) do |result|
          assert_equal Hashie::Mash, result.class
        end
      end
    end
    
    def test_get_account_posts
      vcr_cassette('bridge_get_account_posts', record: :once) do
        options = {
          sort: 'blog',
          account: 'alice',
          start_author: '',
          start_permlink: '',
          limit: 1,
          observer: 'alice'
        }
        
        @api.get_account_posts(options) do |result|
          assert_equal Hashie::Array, result.class
        end
      end
    end
    
    def test_get_ranked_posts
      vcr_cassette('bridge_get_ranked_posts', record: :once) do
        options = {
          sort: 'trending',
          tag: '',
          observer: 'alice',
          limit: 1
        }
        
        @api.get_ranked_posts(options) do |result|
          assert_equal Hashie::Array, result.class
        end
      end
    end
    
    def test_get_profile
      vcr_cassette('bridge_get_profile', record: :once) do
        options = {
          account: 'bob',
          observer: 'alice'
        }
        
        @api.get_profile(options) do |result|
          assert_equal Hashie::Mash, result.class
        end
      end
    end
    
    def test_get_trending_topics
      vcr_cassette('bridge_get_trending_topics', record: :once) do
        limit = 25
        options = {
          limit: limit,
          observer: 'alice'
        }
        
        @api.get_trending_topics(options) do |result|
          assert_equal Hashie::Array, result.class
          assert_equal limit, result.size
        end
      end
    end
    
    def test_get_trending_topics_over_limit
      vcr_cassette('bridge_get_trending_topics_over_limit', record: :once) do
        limit = 26
        options = {
          limit: limit,
          observer: 'alice'
        }
        
        assert_raises Hive::ArgumentError do
          begin
            @api.get_trending_topics(options)
          rescue Hive::PluginNotEnabledError => e
            skip e.inspect
          end
        end
      end
    end
    
    def test_post_notifications_empty
      vcr_cassette('bridge_post_notifications', record: :once) do
        limit = 0
        options = {
          author: '',
          permlink: '',
          last_id: '',
          min_score: 25,
          limit: limit
        }
        
        assert_raises Hive::ArgumentError do
          begin
            @api.post_notifications(options)
          rescue Hive::PluginNotEnabledError => e
            skip e.inspect
          end
        end
      end
    end
    
    def test_unread_notifications
      vcr_cassette('bridge_unread_notifications', record: :once) do
        options = {
          account: 'alice',
          min_score: 25
        }
        
        @api.unread_notifications(options) do |result|
          assert_equal Hashie::Mash, result.class
        end
      end
    end
    
    def test_get_payout_stats
      vcr_cassette('bridge_get_payout_stats', record: :once) do
        limit = 250
        options = {
          limit: limit
        }
        
        @api.get_payout_stats(options) do |result|
          assert_equal Hashie::Mash, result.class
          assert_equal limit, result.items.size
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
    
    def test_list_communities_empty
      vcr_cassette('bridge_list_communities_empty', record: :once) do
        options = {
          last: '',
          limit: 0,
          query: '',
          sort: '',
          observer: ''
        }
        
        assert_raises Hive::ArgumentError do
          begin
            @api.list_communities(options)
          rescue Hive::PluginNotEnabledError => e
            skip e.inspect
          end
        end
      end
    end
    
    def test_list_communities
      vcr_cassette('bridge_list_communities', record: :once) do
        options = {
          last: '',
          limit: 1,
          query: '',
          sort: 'rank',
          observer: 'alice'
        }
        
        @api.list_communities(options) do |result|
          assert_equal Hashie::Array, result.class
        end
      end
    end
    
    def test_list_pop_communities
      skip 'not implemented'
      
      vcr_cassette('bridge_list_pop_communities', record: :once) do
        options = {
          limit: 1
        }
        
        assert_nil @api.list_pop_communities(options)
      end
    end
    
    def test_list_pop_communities_over_limit
      skip 'not implemented'
      
      vcr_cassette('bridge_list_pop_communities_over_limit', record: :once) do
        options = {
          limit: 26
        }
        
        assert_nil @api.list_pop_communities(options)
      end
    end
  end
  
  def test_list_subscribers
    vcr_cassette('bridge_list_subscribers', record: :once) do
      options = {
        community: 'hive-100525'
      }
      
      @api.list_subscribers(options) do |result|
        assert_equal Hashie::Array, result.class
      end
    end
  end
end
