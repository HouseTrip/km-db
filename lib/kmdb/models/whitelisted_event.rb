require 'kmdb'
require 'active_record'
require 'set'

module KMDB
  class WhitelistedEvent < ActiveRecord::Base
    module ClassMethods
      def include?(name)
        _data.include?(name)
      end

      private

      def _data
        @_data ||= Set.new(pluck(:name))
      end
    end
    extend ClassMethods
  end
end
