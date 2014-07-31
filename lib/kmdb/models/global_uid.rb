require 'kmdb'
require 'kmdb/redis'

module KMDB
  # Efficiently generate cross-process globally unique IDs
  # pernamespace, using Redis.
  class GlobalUID

    def self.get(ns = 'value')
      @instances ||= {}
      @instances[ns] ||= new(ns)
      @instances[ns].get
    end

    def initialize(ns)
      @ns = ns
      @major = nil
      @minor = nil
    end

    def get
      if @major.nil? || @minor >= BATCH_SIZE
        @major = _redis.incr(@ns) % (1 << 48)
        @minor = 0
      end

      uid = (@major - 1) * BATCH_SIZE + @minor
      @minor += 1
      return uid
    end

    private

    BATCH_SIZE = 100

    def _redis
      @@_redis ||= Redis.namespaced('kmdb:globaluid:v2')
    end
  end
end
