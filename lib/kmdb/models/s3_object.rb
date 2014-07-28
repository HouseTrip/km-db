require 'kmdb'
require 'kmdb/s3_bucket'
require 'tempfile'

module KMDB
  class S3Object
    def initialize(path)
      @path   = path
    end

    def exist?
      !!_file
    end

    def download(target)
      raise "JSON file for revision #{@revision} not found" unless exist?
      _log "downloading"
      system 'curl', '-o', _tempfile.path, '--silent', _file.url(_expiry)
      raise "Download failed for #{@path}" unless $?.success?
      target.parent.mkpath
      File.rename(_tempfile.path, target.to_s)
      true
    end

    private

    def _file
      @_file ||= begin
        _log "checking for existence"
        S3Bucket.instance.files.head(@path)
      end
    end

    def _expiry
      Time.now.utc.to_i + 600
    end

    def _tempfile
      @_tempfile ||= begin
        Pathname.new('tmp').mkpath
        Tempfile.new('kmdb', 'tmp')
      end
    end

    def _tempdir
      Pathname.new('tmp/').mk
    end

    def _log(message)
      $stderr.write("s3 #{@path}: #{message}\n")
    end
  end
end

