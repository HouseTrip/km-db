require 'fog'
require 'tempfile'

module KMDB
  class Downloader
    def initialize(revision, path)
      @revision = revision
      @path     = path
    end

    def run
      file = _directory.files.head("revisions/#{@revision}.json")
      raise "JSON file for revision #{@revision} not found" if file.nil?

      system 'curl', '-o', _tempfile.path, '--silent', file.url(_expiry)
      raise "Download failed for revision #{@revision}" unless $?.success?
      File.rename(_tempfile.path, @path.to_s)
      true
    end

    private

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
  end
end

