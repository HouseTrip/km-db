require 'kmdb'
require 'pathname'
require 'kmdb/models/dumpfile'
require 'kmdb/models/event_batch'
require 'kmdb/jobs/locked'
require 'kmdb/jobs/record_batch'
require 'kmdb/resque'
require 'oj'

module KMDB
  module Jobs
    # Reads a file from disk, 
    # queues jobs for chunks of events.
    class ParseFile < Locked
      @queue = :low

      def self.perform(id)
        new(JsonFile.new(id)).work
      end

      def initialize(file)
        @file = file
      end
      
      def work
        current_batch = []
        current_stamp = nil

        _each_event_in_file(@file) do |event|
          if event.nil?
            _save_batch(current_batch)
            true
          elsif current_batch.length > _batch_size && event['_t'] != current_stamp
            _save_batch(current_batch)
            current_batch << event
            true
          else
            current_batch << event
            false
          end
        end
      end

      private

      def _batch_size
        250
      end

      def _save_batch(batch)
        saved_batch = EventBatch.new(batch).save!
        Resque.enqueue(Jobs::RecordBatch, saved_batch.id)
        batch.clear
      end
     
      # yields event hashes; yields nil once after the last event.
      # notes down progress in Dumpfile when the yield returns true.
      def _each_event_in_file(file)
        file.open do |input|
          meta = file.metadata
          log "Parsing file #{file.revision} from offset #{meta.offset}"
          input.seek(meta.offset)
          while true
            line = input.gets
            if yield _parse_event(line)
              meta.set(input.tell)
            end
            break if line.nil?
          end
        end
      end

      # text line in, event hash out
      def _parse_event(text)
        return if text.nil?

        # filter strange utf-8 encoding/escaping found in KM dumps   
        if text =~ /(\\[0-9]{3})+/
          begin
            text = eval("%Q(#{text})") 
          rescue SyntaxError => e
            log "Syntax error in: #{text}"
            raise e if @abort_on_error
          end
        end

        begin
          data = Oj.load(text)
        rescue Oj::ParseError => e
          log "Warning, JSON parse error in: #{text}"
          raise e if @abort_on_error
          return
        end

        if data.nil?
          log "Warning, JSON parse failed in: #{text}"
          return
        end

        return data
      end

      def log(message)
        $stderr.write("#{message}\n")
      end
    end
  end
end
