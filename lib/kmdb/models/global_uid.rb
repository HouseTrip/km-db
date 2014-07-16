require 'kmdb'
require 'kmdb/redis'

module KMDB
  module GlobalUID
    module ModuleMethods
      def get(ns = 'value')
        _redis.incr(ns) % (1 << 31)
      end

      private

      def _redis
        @_redis ||= Redis.namespaced('kmdb:globaluid')
      end
    end
    extend ModuleMethods
  end
end
