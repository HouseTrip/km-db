=begin

  Base class for KM data.
  Connect to a secondary database to store events, users, & properties.

  FIXME: the database connection is hard-coded for now.

=end

require 'active_record'
require 'erb'
require 'yaml'


module KMDB
  module CustomRecord
    def self.included(by)
      by.extend ClassMethods
    end

    module ClassMethods
      def disable_index
        connection.execute %Q{
          ALTER TABLE `#{table_name}` DISABLE KEYS;
        }
      end

      def enable_index
        connection.execute %Q{
          ALTER TABLE `#{table_name}` ENABLE KEYS;
        }
      end

      def find_or_create(options)
        where(options).first || create!(options)
      end

    end
  end
end
