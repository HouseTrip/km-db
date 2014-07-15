require 'redis'

module KMDB
  module Redis
    module ModuleMethods
      def connection
        @_connection ||= ::Redis.new(url: ENV.fetch('KMDB_REDIS_URL', 'localhost'))
      end
    end
    extend ModuleMethods
  end
end
