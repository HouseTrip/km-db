require 'kmdb'
require 'kmdb/resque'
require 'pathname'
require 'kmdb/jobs/parse_file'

module KMDB
  module Jobs
    # Lists files in a directory,
    # queues parse jobs for each
    class ListFiles
      @queue = :low

      def self.perform(*paths)
        new(*paths).work
      end

      def initialize(*paths)
        @paths = paths
      end

      def work
        paths = @paths.map { |arg| 
          Pathname.new(arg)
        }.map { |pn|
          pn.exist? and pn or raise "No such file or directory '#{pn}'"
        }.map { |pn|
          pn.directory? ? _list_jsons_in_directory(pn) : pn
        }.flatten

        paths.each do |path|
          Resque.enqueue(ParseFile, path.to_s)
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
