require 'kmdb'
require 'kmdb/concerns/table_regexp'
require 'active_record'

module KMDB
  class WhitelistedEvent < ActiveRecord::Base
    extend TableRegexp

    def self.include?(name)
      !! (regexp == :empty ? true : regexp.match(name))
    end
  end
end
