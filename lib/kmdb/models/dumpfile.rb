require 'kmdb/models/custom_record'

module KMDB
  # Remembers which JSON files where imported, and up to which point.
  class Dumpfile < ActiveRecord::Base
    include CustomRecord

    validates_presence_of :offset
    validates_presence_of :path

    def set(offset)
      update_attributes!(offset: offset)
    end

    def offset
      attributes['offset'] || 0
    end

    def self.get(pathname)
      find_or_create(path: pathname.cleanpath.to_s)
    end
  end
end
