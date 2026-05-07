require 'test_helper'

module Hive
  class BlockApiTest < Hive::Test
    def setup
      @block_api = BlockApi.new(url: TEST_NODE)
      @jsonrpc = Jsonrpc.new(url: TEST_NODE)
      vcr_cassette('jsonrpc_get_methods', record: :once) do
        @methods = @jsonrpc.get_api_methods[@block_api.class.api_name]
      end
    end
    
    def test_get_blocks
      vcr_cassette('block_api_get_blocks', record: :once) do
        loop = 0
        @block_api.get_blocks(block_range: 9001..9010) do |block|
          assert_equal Hashie::Mash, block.class
          loop += 1
        end
        assert_equal 10, loop
      end
    end
    
    def test_get_blocks_large
      vcr_cassette('block_api_get_blocks_large', record: :once) do
        loop = 0
        @block_api.get_blocks(block_range: 1..2000) do |block|
          assert_equal Hashie::Mash, block.class
          loop += 1
        end
        
        assert_equal 2000, loop
      end
    end
    
    def test_get_blocks_zero
      vcr_cassette('block_api_get_blocks_zero', record: :once) do
        @block_api.get_blocks(block_range: []) do |block|
          fail 'Did not expect blocks'
        end
      end
      
      assert true
    end
    
    def test_get_blocks_use_batch
      vcr_cassette('block_api_get_blocks_use_batch', record: :once) do
        loop = 0
        @block_api.get_blocks(block_range: 9001..9010, use_batch: true) do |block|
          assert_equal Hashie::Mash, block.class
          loop += 1
        end
        assert_equal 10, loop
      end
    end
    
    def test_get_blocks_no_closure
      vcr_cassette('block_api_blocks_no_closure', record: :once) do
        blocks = @block_api.get_blocks(block_range: 9001..9010)
        assert_equal Array, blocks.class
      end
    end
    
    def test_get_block
      vcr_cassette('block_api_get_block', record: :once) do
        @block_api.get_block(block_num: 12345678) do |block|
          assert_equal Hashie::Mash, block.class
        end
      end
    end
    
    def test_get_block_no_closure
      vcr_cassette('block_api_block_no_closure', record: :once) do
        result = @block_api.get_block(block_num: 12345678)
        assert_equal Hashie::Mash, result.class
      end
    end
    
    def test_get_block_header
      vcr_cassette('block_api_get_block_header', record: :once) do
        @block_api.get_block_header(block_num: 12345678) do |block|
          assert_equal Hashie::Mash, block.class
        end
      end
    end
    
    def test_block_header_wrong_arguments
      vcr_cassette('block_api_get_block_header_wrong_arguments', record: :once) do
        stderr = STDERR.clone
        stderr.reopen File.new('/dev/null', 'w')
        test_block_api = BlockApi.new(error_pipe: stderr)
        test_block_api.get_block_header(block_num: 12345678) do |block|
          assert_equal Hashie::Mash, block.class
        end
        
        begin
          test_block_api.get_block_header(false)
          # :nocov:
          fail 'please review this test'
          # :nocov:
        rescue Hive::ArgumentError => e
          assert e.to_s, 'expect string from argument error'
        end
        
        begin
          monkey = {}
          monkey.define_singleton_method(:to_h) { raise 'Weird Monkey' }
          test_block_api.get_block_header(monkey)
          # :nocov:
          fail 'please review this test'
          # :nocov:
        rescue UnknownError => e
          assert e.to_s, 'expect string from unknown error'
        end
      end
    end
    
    def test_get_block_range
      skip 'block_api.get_block_range is not exposed by the current node'
      vcr_cassette('block_api_get_block_range', record: :once) do
        block_num = 52802399
        
        @block_api.get_block_range(starting_block_num: block_num, count: 10) do |result|
          blocks = result.blocks.each do |b|
            decoded_previous_block_num = b.previous[0..7].to_i(16)
            previous_block_num = block_num - 1
            
            assert_equal decoded_previous_block_num, previous_block_num, "Wrong block_num.  Got #{decoded_previous_block_num} (#{b.previous}), expected #{previous_block_num}"
            
            block_num = block_num + 1
          end
        end
      end
    end
    
    def test_get_block_range_from_first
      skip 'block_api.get_block_range is not exposed by the current node'
      vcr_cassette('block_api_get_block_range_from_first', record: :once) do
        block_num = 1
        
        @block_api.get_block_range(starting_block_num: block_num, count: 10) do |result|
          blocks = result.blocks.each do |b|
            decoded_previous_block_num = b.previous[0..7].to_i(16)
            previous_block_num = block_num - 1
            
            assert_equal decoded_previous_block_num, previous_block_num, "Wrong block_num.  Got #{decoded_previous_block_num} (#{b.previous}), expected #{previous_block_num}"
            
            block_num = block_num + 1
          end
        end
      end
    end
    
    def test_oddballs
      oddballs = [994240]
      api = Hive::Api.new(url: TEST_NODE)
      
      vcr_cassette('block_api_oddballs', record: :once) do
        oddballs.each do |block_num|
          @block_api.get_block(block_num: block_num) do |b1|
            b1 = b1.block
            
            api.get_block(block_num) do |b2|
              b2.keys.each do |key|
                case key.to_sym
                when :transactions
                  b2[:transactions].each_with_index do |trx2, trx_index|
                    trx1 = b1[:transactions][trx_index]
                    
                    trx2.keys.each do |key|
                      case key.to_sym
                      when :operations
                        trx2[:operations].each_with_index do |op1, op_index|
                          op2 = trx2[:operations][op_index]
                          
                          op1[1].keys.each do |key|
                            case key.to_sym
                            when :fee
                              fee1 = Type::Amount.new(op1[1][:fee])
                              fee2 = Type::Amount.new(op2[1][:fee])
                              
                              assert_equal fee2.to_h, fee1.to_h, "expect the same fee"
                            else
                              assert_equal op2[1][key], op1[1][key], "expect the same operation #{key}"
                            end
                          end
                        end
                      when :transaction_id, :block_num, :transaction_num
                        assert_nil trx1[key], "did not expect nil #{key}"
                        refute_nil trx2[key], "expect nil #{key}"
                      else
                        assert_equal trx2[key], trx1[key], "expect the same transaction #{key}"
                      end
                    end
                  end
                else
                  assert_equal b2[key], b1[key], "expect the same #{key}"
                end
              end
            end
          end
        end
      end
    end
  end
end
