require 'fog'
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
        _directory.files.head(@path)
      end
    end

    def _expiry
      Time.now.utc.to_i + 600
    end

    def _tempfile
      @_tempfile ||= Tempfile.new('kmdb')
    end

    def _directory
      @_directory ||= _connection.directories.get(ENV.fetch('AWS_BUCKET'))
    end
    
    def _connection
      @_connection ||= Fog::Storage.new(
        provider:              'AWS',
        aws_access_key_id:     ENV.fetch('AWS_ACCESS_KEY_ID'),
        aws_secret_access_key: ENV.fetch('AWS_SECRET_ACCESS_KEY')
      )
    end

    def _log(message)
      STDOUT.write("s3 #{@path}: #{message}\n")
    end
  end
end

