require 'redis'
require 'redis-namespace'

module KMDB
  module Redis
    module ModuleMethods
      def connection
        @@_connection ||= ::Redis.new(url: ENV.fetch('KMDB_REDIS_URL', 'localhost'))
      end

      def namespaced(ns)
        ::Redis::Namespace.new(ns, redis: connection)
      end
    end
    extend ModuleMethods
  end
end
