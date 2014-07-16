require 'kmdb'
require 'kmdb/models/dumpfile'
require 'kmdb/downloader'

module KMDB
  # Models one of KissMetrics's JSON dumps.
  # Supports caching them from S3 and finding the latest one.
  class JsonFile
    attr_reader :revision

    def initialize(revision)
      @revision = revision
    end
    
    # Yields an IO object for this file
    def open(&block)
      _cached.open('r') do |io|
        metadata.update_attributes!(length: io.size)
        yield io
      end
    end

    def metadata
      @metadata ||= Dumpfile.get(revision)
    end

    module ClassMethods
      # Looks in the S3 bucket and create Dumpfile records
      # for any missing file.
      def update_list
        raise
      end
    end
    extend ClassMethods

    private

    def _cached
      path = Pathname.new("tmp/#{revision}.json")
      return path if path.exist?
      Downloader.new(revision, path).run
      path
    end
  end
end
