require 'kmdb/models/custom_record'
require 'kmdb/concerns/has_properties'
require 'kmdb/redis'

module KMDB
  class User < ActiveRecord::Base
    include CustomRecord
    include HasProperties

    has_many :events,     class_name: 'KMDB::Event', inverse_of: :user
      # points to the aliased user. if set, no properties/events should belong to this user

    validates_presence_of   :name
    validates_uniqueness_of :name

    scope :named, lambda { |name| where(name: name) }

    # return (latest) value of property
    def prop(name)
      properties.named(name).first.andand.value
    end

    CACHE_EXPIRY = 3_600

    def self.find_or_create(name:)
      if raw = _redis.get(name)
        Marshal.load(raw)
      else
        super.tap do |user|
          _redis.set(name, Marshal.dump(user), ex: CACHE_EXPIRY)
        end
      end
    end

    def destroy
      super
      _redis.del(name)
    end

    private

    def _redis(*args)
      self.class._redis(*args)
    end

    def self._redis
      @_redis ||= Redis.namespaced('kmdb:users')
    end
  end
end
