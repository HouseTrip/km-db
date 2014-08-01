require 'kmdb'
require 'kmdb/models/dumpfile'
require 'kmdb/models/s3_object'

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
      _flush_cache if _should_flush?
    end

    def exist?
      _cached_path.exist? || _s3object.exist?
    end

    def metadata
      @metadata ||= Dumpfile.get(revision)
    end

    private

    def _should_flush?
      !! (ENV.fetch('KMDB_KEEP_FILES', 'YES') !~ /YES/)
    end

    def _flush_cache
      _cached_path.delete if _cached_path.exist?
    end

    def _cached
      return _cached_path if _cached_path.exist?
      _s3object.download(_cached_path)
      _cached_path
    end

    def _cached_path
      @_cached_path ||= Pathname.new("tmp/#{revision}.json")
    end

    def _s3object
      @_s3object ||= S3Object.new("revisions/#{revision}.json")
    end
  end
end
