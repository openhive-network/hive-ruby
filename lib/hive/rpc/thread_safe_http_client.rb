module Hive
  module RPC
    # {ThreadSafeHttpClient} is the default RPC Client used by `hive-ruby.`
    # It's perfect for simple requests.  But for higher performance, it's better
    # to override {HttpClient} and implement something other than {Net::HTTP}.
    # 
    # It performs http requests in a {Mutex} critical section because {Net::HTTP}
    # is not thread safe.  This is the very minimum level thread safety
    # available.
    class ThreadSafeHttpClient < HttpClient
      SEMAPHORE = Mutex.new.freeze
      
      # Same as #{HttpClient#http_post}, but returns a fresh request object.
      # Reusing mutable Net::HTTP::Post instances across nested/retried calls can
      # leak request bodies between rpc executions.
      def http_post(api_name)
        raise "Namespace required." if api_name.nil?

        Net::HTTP::Post.new(uri.request_uri, POST_HEADERS)
      end
      
      def http_request(request); SEMAPHORE.synchronize{super}; end
      
      # Same as #{BaseClient#rpc_id}, auto-increment, but scoped to each thread
      # so it is thread safe.
      def rpc_id
        thread = Thread.current
        rpc_id = thread.thread_variable_get(:rpc_id)
        rpc_id ||= 0
        rpc_id += 1
        thread.thread_variable_set(:rpc_id, rpc_id)
      end
    end
  end
end
