require 'kmdb/models/custom_record'
require 'kmdb/models/json_file'

module KMDB
  # Remembers which JSON files where imported, and up to which point.
  class Dumpfile < ActiveRecord::Base
    include CustomRecord

    validates_presence_of :offset
    validates_presence_of :revision

    def set(offset)
      update_attributes!(offset: offset)
    end

    def offset
      attributes['offset'] || 0
    end

    def file
      JsonFile.new(revision)
    end

    def complete?
      return if offset.nil? || length.nil?
      offset >= length
    end

    def self.get(revision)
      find_or_create(revision: revision)
    end
  end
end
