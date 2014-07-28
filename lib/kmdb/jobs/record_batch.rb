require 'kmdb'
require 'kmdb/resque'
require 'kmdb/models/event_batch'
require 'kmdb/models/user'
require 'kmdb/models/alias'
require 'kmdb/models/event'
require 'kmdb/models/property'
require 'kmdb/models/global_uid'
require 'kmdb/models/ignored_user'
require 'kmdb/models/whitelisted_event'
require 'kmdb/jobs/locked'
require 'kmdb/jobs/unalias_user'

module KMDB
  module Jobs
    class RecordBatch < Locked
      @queue = :high

      def self.perform(id)
        new(id).work
      end

      def initialize(id)
        @batch = EventBatch.find(id)
        raise ArgumentError.new('no such batch') if @batch.nil?
      end

      def work
        event_sql = []
        properties_sql = []

        @batch.events.each do |event|
          # reject non-whitelisted events
          next unless event['_n'].nil? || WhitelistedEvent.include?(event['_n'])

          # reject ignored users 
          next if IgnoredUser.include?(event['_p']) ||
                  IgnoredUser.include?(event['_p2'])

          # store depending on event type
          if event['_p2']
            # ignore aliasing between "real" users
            next if event['_p'] =~ /^\d+$/ && event['_p2'] =~ /^\d+$/
            aliaz = Alias.record event['_p'], event['_p2'], event['_t']
            Resque.enqueue(UnaliasUser, aliaz.name1, aliaz.name2)
          elsif event['_n']
            Event.sql_for(event) do |e,p|
              event_sql << e
              properties_sql << p
            end
          else
            properties_sql << Property.sql_for(event) 
          end
        end

        KMDB.transaction do |c|
          Event.mass_create(event_sql.compact)
          Property.mass_create(properties_sql.compact)
        end

        @batch.delete
      end
    end
  end
end
