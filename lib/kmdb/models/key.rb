require 'kmdb/models/custom_record'

module KMDB
  # Map strings (event and property names) to unique integers (Key#id) for performance
  class Key < ActiveRecord::Base
    include CustomRecord

    MAX_SIZE = 255

    has_many :events,     foreign_key: :n,   class_name: 'KMDB::Event',    dependent: :delete_all
    has_many :properties, foreign_key: :key, class_name: 'KMDB::Property', dependent: :delete_all


    def self.get(string)
      @cache ||= {}
      @cache[string] ||= get_uncached(string)
    end

    # Replace each duplicate key ID with its most-used variant

  private

    def self.get_uncached(string)
      string.size <= MAX_SIZE or raise "String is too long"
      find_or_create(string: string).id
    end
  end
end
