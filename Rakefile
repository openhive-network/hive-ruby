require 'bundler/gem_tasks'
require 'rake/testtask'
require 'yard'
require 'hive'

Rake::TestTask.new(test: ['clean:vcr', 'test:threads']) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.test_files = FileList['test/**/*_test.rb']
  t.ruby_opts << if ENV['HELL_ENABLED']
    '-W2'
  else
    '-W1'
  end
end

namespace :test do
  Rake::TestTask.new(static: 'clean:vcr') do |t|
    t.description = <<-EOD
      Run static tests, which are those that have static request/responses.
      These are tests that are typically read-only and do not require heavy
      matches on the json-rpc request body.  Often, the only difference between
      one execution and another is the json-rpc-id.
    EOD
    t.libs << 'test'
    t.libs << 'lib'
    t.test_files = [
      'test/hive/account_by_key_api_test.rb',
      'test/hive/account_history_api_test.rb',
      'test/hive/block_api_test.rb',
      'test/hive/database_api_test.rb',
      'test/hive/follow_api_test.rb',
      'test/hive/jsonrpc_test.rb',
      'test/hive/market_history_api_test.rb',
      'test/hive/tags_api_test.rb',
      'test/hive/witness_api_test.rb'
    ]
    t.ruby_opts << if ENV['HELL_ENABLED']
      '-W2'
    else
      '-W1'
    end
  end
  
  Rake::TestTask.new(broadcast: 'clean:vcr') do |t|
    t.description = <<-EOD
      Run broadcast tests, which are those that only use network_broadcast_api
      and/or database_api.verify_authority (pretend: true).
    EOD
    t.libs << 'test'
    t.libs << 'lib'
    t.test_files = [
      'test/hive/broadcast_test.rb',
      'test/hive/transaction_builder_test.rb'
    ]
    t.ruby_opts << if ENV['HELL_ENABLED']
      '-W2'
    else
      '-W1'
    end
  end
  
  Rake::TestTask.new(testnet: 'clean:vcr') do |t|
    t.description = <<-EOD
      Run testnet tests, which are those that use network_broadcast_api to do
      actual broadcast operations, on a specified (or default) testnet.
    EOD
    t.libs << 'test'
    t.libs << 'lib'
    t.test_files = [
      'test/hive/testnet_test.rb'
    ]
    t.ruby_opts << if ENV['HELL_ENABLED']
      '-W2'
    else
      '-W1'
    end
  end
  
  desc 'Tests the API using multiple threads.'
  task :threads do
    next if !!ENV['TEST']
    
    threads = []
    api = Hive::Api.new(url: ENV['TEST_NODE'])
    database_api = Hive::DatabaseApi.new(url: ENV['TEST_NODE'])
    witnesses = {}
    keys = %i(created url total_missed props running_version
      hardfork_version_vote hardfork_time_vote)
    low_participation_warning_seen = false
    
    if defined? Thread.report_on_exception
      Thread.report_on_exception = true
    end
    
    database_api.get_active_witnesses do |result|
      abort 'Bad result from: database_api.get_active_witnesses' if result.nil?
      
      print "Found #{result.witnesses.size} witnesses ..."
      
      result.witnesses.each do |witness_name|
        if witness_name == '' && !low_participation_warning_seen
          warn "\nWarning: low witness participation detected."
          low_participation_warning_seen = true
          
          next
        end
        
        threads << Thread.new do
          api.get_witness_by_account(witness_name) do |witness|
            witnesses[witness.owner] = witness.map do |k, v|
              [k, v] if keys.include? k.to_sym
            end.compact.to_h
            
            hbd_exchange_rate = witness[:hbd_exchange_rate] || witness[:hbd_exchange_rate]
            base = hbd_exchange_rate[:base].to_f
            
            if (quote = hbd_exchange_rate[:quote].to_f) > 0
              rate = (base / quote).round(3)
              witnesses[witness.owner][:hbd_exchange_rate] = rate
            else
              witnesses[witness.owner][:hbd_exchange_rate] = nil
            end
            
            last_hbd_exchange_update = witness[:last_hbd_exchange_update] || witness[:last_hbd_exchange_update]
            last_hbd_exchange_update = Time.parse(last_hbd_exchange_update + 'Z')
            last_hbd_exchange_elapsed = '%.2f hours ago' % ((Time.now.utc - last_hbd_exchange_update) / 60)
            witnesses[witness.owner][:last_hbd_exchange_elapsed] = last_hbd_exchange_elapsed
          end
        end
      end
    end
    
    threads.each do |thread|
      print '.'
      thread.join
    end
    
    puts ' done!'
    
    if threads.size != witnesses.size
      puts "Bug: expected #{threads.size} witnesses, only found #{witnesses.size}."
    else
      puts JSON.pretty_generate witnesses rescue puts witnesses
    end
  end
end
  
namespace :stream do
  desc 'Test the ability to stream a block range.'
  task :block_range, [:mode, :at_block_num] do |t, args|
    mode = (args[:mode] || 'irreversible').to_sym
    first_block_num = args[:at_block_num].to_i if !!args[:at_block_num]
    stream = Hive::Stream.new(url: ENV['TEST_NODE'], mode: mode)
    api = Hive::Api.new(url: ENV['TEST_NODE'])
    block_api = Hive::BlockApi.new(url: ENV['TEST_NODE'])
    last_block_num = nil
    last_timestamp = nil
    range_complete = false
    round_pool = {}
    aging_blocks = {}
    aged_block_interval = 630
    
    api.get_dynamic_global_properties do |properties|
      current_block_num = if mode == :head
        properties.head_block_number
      else
        properties.last_irreversible_block_num
      end
      
      # First pass replays latest a random number of blocks to test chunking.
      first_block_num ||= current_block_num - (rand * 2000).to_i
      
      range = first_block_num..current_block_num
      puts "Initial block range: #{range.size}"
      
      stream.blocks(at_block_num: range.first) do |block, block_num|
        current_timestamp = Time.parse(block.timestamp + 'Z')
        round_pool[current_timestamp] = {block_num: block_num, block: block}
        
        if !range_complete && block_num > range.last
          puts 'Done with initial range.'
          range_complete = true
        end
        
        if !!last_timestamp && block_num != last_block_num + 1
          puts "Bug: Last block number was #{last_block_num} then jumped to: #{block_num}"
          exit
        end
        
        if !!last_timestamp && current_timestamp < last_timestamp
          puts "Bug: Went back in time.  Last timestamp was #{last_timestamp}, then jumped back to #{current_timestamp}"
          exit
        end
        
        round_pool.each do |k, v|
          aging_blocks[k] = v if Time.now - k > aged_block_interval
        end
        
        round_pool = round_pool.select{|k, v| Time.now - k <= aged_block_interval}.to_h
        drift = last_timestamp.nil? ? 0 : (current_timestamp - last_timestamp) - Hive::Stream::BLOCK_INTERVAL.to_f
        
        puts "\t#{block_num} Timestamp: #{current_timestamp}, witness: #{block.witness}, aging blocks: #{aging_blocks.size}, drift: #{drift}"
        
        last_block_num = block_num
        last_timestamp = current_timestamp
        
        if range_complete && aging_blocks.any?
          aging_block_nums = aging_blocks.map{|k, v| v[:block_num]}
          wire_block_range = (aging_block_nums.first..aging_block_nums.last)
          
          block_api.get_block_headers(block_range: wire_block_range) do |wire_header, wire_block_num|
            wire_timestamp = Time.parse(wire_header.timestamp + 'Z')
            aging_block = aging_blocks[wire_timestamp][:block]
            
            if wire_header.previous == aging_block.previous
              puts "\t\tAged block test #{wire_block_num}: √"
              aging_blocks.delete(wire_timestamp)
            else
              puts "\t\tAged block test #{wire_block_num}: detected block-reorganization (#{wire_header.previous} != #{aging_block.previous})"
              exit
            end
          end
        end
      end
    end
  end
  
  desc 'Test the ability to stream a block range of transactions.'
  task :trx_range, [:mode, :at_block_num] do |t, args|
    mode = (args[:mode] || 'irreversible').to_sym
    first_block_num = args[:at_block_num].to_i if !!args[:at_block_num]
    stream = Hive::Stream.new(url: ENV['TEST_NODE'], mode: mode)
    api = Hive::Api.new(url: ENV['TEST_NODE'])
    
    api.get_dynamic_global_properties do |properties|
      current_block_num = if mode == :head
        properties.head_block_number
      else
        properties.last_irreversible_block_num
      end
      
      # First pass replays latest a random number of blocks to test chunking.
      first_block_num ||= current_block_num - (rand * 200).to_i
      
      stream.transactions(at_block_num: first_block_num) do |trx, trx_id, block_num|
        puts "#{block_num} :: #{trx_id}; ops: #{trx.operations.map(&:type).join(', ')}"
      end
    end
  end
  
  desc 'Test the ability to stream a block range of operations.'
  task :op_range, [:mode, :at_block_num] do |t, args|
    mode = (args[:mode] || 'irreversible').to_sym
    first_block_num = args[:at_block_num].to_i if !!args[:at_block_num]
    stream = Hive::Stream.new(url: ENV['TEST_NODE'], mode: mode)
    api = Hive::Api.new(url: ENV['TEST_NODE'])
    
    api.get_dynamic_global_properties do |properties|
      current_block_num = if mode == :head
        properties.head_block_number
      else
        properties.last_irreversible_block_num
      end
      
      # First pass replays latest a random number of blocks to test chunking.
      first_block_num ||= current_block_num - (rand * 200).to_i
      
      stream.operations(at_block_num: first_block_num) do |op, trx_id, block_num|
        puts "#{block_num} :: #{trx_id}; op: #{op.type}"
      end
    end
  end
  
  desc 'Test the ability to stream a block range of virtual operations.'
  task :vop_range, [:mode, :at_block_num] do |t, args|
    mode = (args[:mode] || 'irreversible').to_sym
    first_block_num = args[:at_block_num].to_i if !!args[:at_block_num]
    stream = Hive::Stream.new(url: ENV['TEST_NODE'], mode: mode)
    api = Hive::Api.new(url: ENV['TEST_NODE'])
    ah_api = Hive::AccountHistoryApi.new(url: ENV['TEST_NODE'])
    round_vops = {}
    
    api.get_dynamic_global_properties do |properties|
      current_block_num = if mode == :head
        properties.head_block_number
      else
        properties.last_irreversible_block_num
      end
      
      # First pass replays latest a random number of blocks to test chunking.
      first_block_num ||= current_block_num - (rand * 200).to_i
      
      stream.operations(at_block_num: first_block_num, only_virtual: true) do |op, trx_id, block_num|
        # 126 is about two shuffle rounds (if mode == :head), we need to avoid
        # the current block_num because we're still in the middle of reading
        # all of the vops for that block.
        if round_vops.size > 126 && !round_vops.include?(block_num)
          ah_api.enum_virtual_ops(block_range_begin: round_vops.keys.min, block_range_end: round_vops.keys.max + 1, include_reversible: true) do |result|
            round_vops.each do |k, v|
              later_ops = result.ops.select{|vop| vop.block == k}
              if (verify_count = later_ops.size) == v.size
                puts "\t\t#{k} :: streamed vop count was #{v.size} √"
              else
                puts "\t\t#{k} :: streamed vop count was #{v.size}, later became #{verify_count}"
                puts "\t\t\t#{v.map{|op| op.type}.join(', ')}"
                puts "\t\tLater ops:\n\t\t\t#{later_ops.map{|vop| vop.op.type}.join(', ')}"
                
                exit
              end
            end
          end
          
          round_vops = {}
        end
        
        round_vops[block_num] ||= []
        round_vops[block_num] << op
        
        puts "#{block_num} :: #{trx_id}; op: #{op.type}"
      end
    end
  end
  
  desc 'Test the ability to stream a block range of all operations (including virtual).'
  task :all_op_range, [:mode, :at_block_num] do |t, args|
    mode = (args[:mode] || 'irreversible').to_sym
    first_block_num = args[:at_block_num].to_i if !!args[:at_block_num]
    stream = Hive::Stream.new(url: ENV['TEST_NODE'], mode: mode)
    api = Hive::Api.new(url: ENV['TEST_NODE'])
    
    api.get_dynamic_global_properties do |properties|
      current_block_num = if mode == :head
        properties.head_block_number
      else
        properties.last_irreversible_block_num
      end
      
      # First pass replays latest a random number of blocks to test chunking.
      first_block_num ||= current_block_num - (rand * 200).to_i
      
      stream.operations(at_block_num: first_block_num, include_virtual: true) do |op, trx_id, block_num|
        puts "#{block_num} :: #{trx_id}; op: #{op.type}"
      end
    end
  end
  
  desc 'Test the ability to stream all operations (including virtual) that match a pattern.'
  task :op_pattern, [:pattern, :mode, :at_block_num] do |t, args|
    mode = (args[:mode] || 'irreversible').to_sym
    first_block_num = args[:at_block_num].to_i if !!args[:at_block_num]
    stream = Hive::Stream.new(url: ENV['TEST_NODE'], mode: mode)
    api = Hive::Api.new(url: ENV['TEST_NODE'])
    pattern = /#{args[:pattern]}/i
    
    api.get_dynamic_global_properties do |properties|
      current_block_num = if mode == :head
        properties.head_block_number
      else
        properties.last_irreversible_block_num
      end
      
      # First pass replays latest a random number of blocks to test chunking.
      first_block_num ||= current_block_num - (rand * 200).to_i
      
      stream.operations(at_block_num: first_block_num, include_virtual: true) do |op, trx_id, block_num|
        next unless op.to_json =~ pattern
        
        puts "#{block_num} :: #{trx_id}; op: #{op.to_json}"
      end
    end
  end
  
  desc 'Test the ability to stream all effective_comment_vote_operation operations.'
  task :effective_comment_vote_operation, [:mode, :at_block_num] do |t, args|
    mode = (args[:mode] || 'irreversible').to_sym
    first_block_num = args[:at_block_num].to_i if !!args[:at_block_num]
    stream = Hive::Stream.new(url: ENV['TEST_NODE'], mode: mode, no_warn: true)
    api = Hive::Api.new(url: ENV['TEST_NODE'])
    
    api.get_dynamic_global_properties do |properties|
      current_block_num = if mode == :head
        properties.head_block_number
      else
        properties.last_irreversible_block_num
      end
      
      # First pass replays latest a random number of blocks to test chunking.
      first_block_num ||= current_block_num - (rand * 200).to_i
      
      stream.operations(at_block_num: first_block_num, include_virtual: true) do |op, trx_id, block_num|
        next unless op.type == 'effective_comment_vote_operation'
        pending_payout = Hive::Type::Amount.new(op.value.pending_payout)
        
        puts "#{block_num} :: #{trx_id}; voter: #{op.value.voter}, author: #{op.value.author}, pending_payout: #{pending_payout}"
      end
    end
  end
end

desc 'List hardforks.'
task :hardforks do
  database_api = Hive::DatabaseApi.new(url: ENV['TEST_NODE'])
  block_api = Hive::BlockApi.new(url: ENV['TEST_NODE'])
  ah_api = Hive::AccountHistoryApi.new(url: ENV['TEST_NODE'])
  last_hf_timestamp = block_api.get_block(block_num: 1) do |result|
    Time.parse(result.block.timestamp + 'Z')
  end
  
  database_api.get_hardfork_properties do |properties|
    processed_hardforks = properties.processed_hardforks
    
    processed_hardforks.each_with_index do |timestamp, index|
      timestamp = Time.parse(timestamp + 'Z')
      
      puts "HF#{index}: #{timestamp}"
    end
  end
end

YARD::Rake::YardocTask.new do |t|
  t.files = ['lib/**/*.rb']
end

task default: :test

desc 'Ruby console with hive already required.'
task :console do
  exec 'irb -r hive -I ./lib'
end

namespace :clean do
  desc 'Remove test/fixtures/vcr_cassettes/*.yml so they can be rebuilt fresh.'
  task :vcr do |t|
    cmd = 'echo Cleaned cassettes: $(rm -v test/fixtures/vcr_cassettes/*.yml | wc -l)'
    system cmd
  end
end

namespace :show do
  desc 'Shows known API names.'
  task :apis do
    url = ENV['URL']
    jsonrpc = Hive::Jsonrpc.new(url: url)
    api_methods = jsonrpc.get_api_methods
    puts api_methods.keys
  end

  desc 'Shows known method names for specified API.'
  task :methods, [:api] do |t, args|
    url = ENV['URL']
    jsonrpc = Hive::Jsonrpc.new(url: url)
    api_methods = jsonrpc.get_api_methods
    
    api_names = if !!args[:api]
      [args[:api]]
    else
      Hive::Fallback::API_METHODS.keys
    end
    
    api_names.each do |api_name|
      unless !!api_methods[api_name.to_s]
        puts "Skipped API: #{api_name}"
        
        next
      end
      
      api_methods[api_name.to_s].each do |method|
        jsonrpc.get_signature(method: "#{api_name}.#{method}") do |signature|
          print "#{api_name}.#{method} "
          
          params = signature.args.map do |k, v|
            if v =~ /\d{4}-(0[1-9]|1[0-2])-(0[1-9]|[1-2]\d|3[0-1])T(2[0-3]|[01]\d):[0-5]\d:[0-5]\d/
              "#{k}: Time"
            elsif v.class == Hashie::Array
              "#{k}: []"
            elsif v.class == Hashie::Mash
              "#{k}: {}"
            else
              "#{k}: #{v.class}"
            end
          end
          puts params.join(', ')
        end
      end
    end
  end
end
