module Hive
  # {BlockApi} is used to query values related to the block plugin.  It can also
  # be used to access a range of multiple blocks by using
  # {http://www.jsonrpc.org/specification#batch JSON-RPC 2.0 batch} requests.
  #
  # Also see: {https://developers.hive.io/apidefinitions/block-api.html Block API Definitions}
  class BlockApi < Api
    MAX_RANGE_SIZE = 50
    MAX_NO_BATCH_RANGE_SIZE = 200
    MAX_NO_BATCH_NO_RANGE_SIZE = 1
    
    def initialize(options = {})
      self.class.api_name = :block_api
      super
    end
    
    # Uses a batched requst on a range of block headers.
    #
    # @param options [Hash] The attributes to get a block range with.
    # @option options [Range] :block_range starting on one block number and ending on an higher block number.
    def get_block_headers(options = {block_range: (0..0)}, &block)
      get_block_objects(options.merge(object: :block_header), block)
    end
    
    # Uses get_block_range (or batched requsts) on a range of blocks.
    #
    # @param options [Hash] The attributes to get a block range with.
    # @option options [Range] :block_range starting on one block number and ending on an higher block number.
    # @option options [Boolean] :use_batch use json-rpc batch instead of get_block_range (preferred)
    def get_blocks(options = {block_range: (0..0), use_batch: false}, &block)
      get_block_objects(options.merge(object: :block), block)
    end
  private
    def get_block_objects(options = {block_range: (0..0), use_batch: false}, block = nil)
      object = options[:object]
      block_range = options[:block_range] || (0..0)
      use_batch = !!options[:use_batch]
      
      object = :block_range if object == :block && !use_batch
      object_method = "get_#{object}".to_sym
      
      if !!block_range && block_range.any? && (start = block_range.first) < 1
        raise Hive::ArgumentError, "Invalid starting block: #{start}"
      end
      
      chunks = if object == :block_range
        block_range.each_slice(MAX_NO_BATCH_RANGE_SIZE)
      elsif block_range.size > MAX_RANGE_SIZE
        block_range.each_slice(MAX_RANGE_SIZE)
      else
        [block_range]
      end
      
      for sub_range in chunks do
        request_object = []
        
        if !!use_batch
          for i in sub_range do
            @rpc_client.put(self.class.api_name, object_method, block_num: i, request_object: request_object)
          end
        else
          case object
          when :block_header
            # Must use json-rpc batch for block headers request.
            for i in sub_range do
              @rpc_client.put(self.class.api_name, :get_block_header, block_num: i, request_object: request_object)
            end
          when :block, :block_range
            if sub_range.size == 1
              @rpc_client.put(self.class.api_name, :get_block, block_num: sub_range.first, request_object: request_object)
            else
              @rpc_client.put(self.class.api_name, :get_block_range, starting_block_num: sub_range.first, count: sub_range.size, request_object: request_object)
            end
          end
        end
        
        if !!block
          index = 0
          @rpc_client.rpc_batch_execute(api_name: self.class.api_name, request_object: request_object) do |result, error, id|
            raise Hive::RemoteNodeError, error.to_json if !!error
            
            block_num = sub_range.to_a[index]
            index = index + 1
            
            case object
            when :block_header
              block.call(result[:header], block_num)
            else
              if !!use_batch || !!result[:block]
                block.call(result[:block] || result[object], block_num)
              else
                current_block_num = block_num
                result[:blocks].each do |b|
                  # Now verify that the previous block_num really is the
                  # previous block.
                  
                  decoded_previous_block_num = b.previous[0..7].to_i(16)
                  previous_block_num = current_block_num - 1
                  
                  unless decoded_previous_block_num == previous_block_num
                    raise Hive::RemoteNodeError, "Wrong block_num.  Got #{decoded_previous_block_num}, expected #{previous_block_num}"
                  end
                  
                  block.call(b, current_block_num)
                  current_block_num = current_block_num + 1
                end
              end
            end
          end
        else
          blocks = []
          
          @rpc_client.rpc_batch_execute(api_name: self.class.api_name, request_object: request_object) do |result, error, id|
            raise Hive::RemoteNodeError, error.to_json if !!error
            
            blocks << result
          end
        end
      end
      
      blocks
    end
  end
end
