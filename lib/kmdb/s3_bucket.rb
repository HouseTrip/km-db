require 'kmdb'
require 'fog'
require 'singleton'

module KMDB
  class S3Bucket
    include Singleton

    def method_missing(method, *args, &block)
      _directory.send(method, *args, &block)
    end

    def respond_to?(method, all = false)
      _directory.respond_to(method, all)
    end

    private

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


