require 'kmdb'
require 'kmdb/models/dumpfile'
require 'kmdb/models/json_file'
require 'kmdb/jobs/locked'
require 'kmdb/jobs/parse_file'
require 'kmdb/resque'

module KMDB
  module Jobs
    # Detects a batch up new revision files in S3 and adds Dumpfiles for them.
    class FindFiles < Locked
      @queue = :low

      def self.perform
        new.work
      end

      def work
        lookahead = Integer(ENV.fetch('KMDB_REVISION_LOOKAHEAD', 10))
        start_at = Dumpfile.maximum(:revision) || Integer(ENV.fetch('KMDB_MIN_REVISION', 1))

        start_at.upto(start_at + lookahead).map do |revision|
          json_file = JsonFile.new(revision)
          next unless json_file.exist?
          Resque.enqueue(ParseFile, json_file.revision)
        end
      end
    end
  end
end


