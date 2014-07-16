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
        retries ||= 5
        where(options).first || create!(options)
      rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
        $stderr.write("could not create #{self.name} with #{options.inspect}, retrying (#{retries})}\n")
        retry unless (retries -= 1).zero?
        raise
      end

      def commit(tid)
        where(tid: tid).update_all(tid: nil)
      end

      def clear_uncommitted
        # TODO: this needs to be protected by a global lock
        where('tid IS NOT NULL').delete_all
      end
    end
  end
end
