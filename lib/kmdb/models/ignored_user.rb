require 'kmdb'
require 'active_record'

module KMDB
  class IgnoredUser < ActiveRecord::Base
    module ClassMethods
      def include?(name)
        !! _regexp.match(name)
      end

      private

      def _regexp
        @_regexp ||= begin
          all_res = all.to_a.map { |iu| Regexp.new('^%s$' % Regexp.escape(iu.name)) }
          Regexp.union(*all_res)
        end
      end
    end
    extend ClassMethods
  end
end
