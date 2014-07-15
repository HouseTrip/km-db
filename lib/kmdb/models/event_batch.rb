require 'kmdb'
require 'kmdb/redis'
require 'zlib'
require 'digest'

module KMDB
  # Models a list of events, in chronological order,
  # spanning entire seconds.
  # Abstracts (compressed) storage in Redis.
  # This effectively acts as a write cache.
  class EventBatch
    # provide either and Array (when creating a batch)
    # or and encoded String (when loading)
    def initialize(data, id:nil)
      case data
      when Array
        @events = data
      when String
        @encoded = data
        @id = id
      else
        raise ArgumentError
      end
    end

    def save!
      _check_redis_space!
      redis.set(id, _encoded)
      self
    end

    def delete
      redis.del(id)
    end

    def self.find(id)
      encoded = redis.get(id)
      return if encoded.nil?
      new(encoded, id: id)
    end

    def events
      @events ||= Marshal.load(Zlib.inflate(@encoded))
    end

    def id
      @id ||= Digest::MD5.hexdigest(_encoded)
    end

    private

    def _encoded
      @encoded ||= Zlib.deflate(Marshal.dump(@events), 3)
    end

    # raise exception if space in Redis is getting low
    def _check_redis_space!
      # FIXME: not implemented
      # raise RuntimeError.new('low Redis storage space')
      nil
    end

    module SharedMethods
      def redis
        KMDB::Redis.connection
      end
    end
    include SharedMethods
    extend SharedMethods
  end
end
