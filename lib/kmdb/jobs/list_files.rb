require 'kmdb'
require 'kmdb/resque'
require 'pathname'
require 'kmdb/jobs/locked'
require 'kmdb/jobs/parse_file'
require 'kmdb/models/dumpfile'

module KMDB
  module Jobs
    # Lists known dump files, queues parse jobs for each
    class ListFiles < Locked
      @queue = :low

      def self.perform
        new.work
      end

      def work
        Dumpfile.find_each do |meta|
          next if meta.complete?
          Resque.enqueue(ParseFile, meta.revision)
        end
      end

      private

      def _list_jsons_in_directory(directory)
        input_fns = []
        directory.find do |input_pn|
          input_pn.extname == '.json' or next
          input_fns << input_pn
        end
        input_fns.sort
      end
    end
  end
end
