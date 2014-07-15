require 'kmdb'
require 'kmdb/models/event_batch'
require 'kmdb/models/user'
require 'kmdb/models/event'
require 'kmdb/models/property'

module KMDB
  module Jobs
    class ParseBatch
      @queue = :high

      def self.perform(id)
        new(id).work
      end

      def initialize(id)
        @batch = EventBatch.find(id)
        raise ArgumentError.new('no such batch') if @batch.nil?
      end

      def work
        KMDB.transaction do
          @batch.events.each do |event|
            if event['_p2']
              User.alias! event['_p'], event['_p2']
            elsif event['_n']
              Event.record event
            else
              Property.set event
            end
          end
        end

        @batch.delete
      end
    end
  end
end
