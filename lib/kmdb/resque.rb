require 'resque'
require 'kmdb/redis'

module KMDB
  module Resque
    module ModuleMethods
      def enqueue(*args)
        _configure
        ::Resque.enqueue(*args)
      rescue StandardError => e
        binding.pry
      end

      def work
        _configure
        ::Resque::Worker.new(:high, :medium, :low).tap do |w|
          w.term_timeout = 8
          w.term_child   = true
          w.log "starting worker"
          w.work(5) # interval
        end
      end

      def configure
        _configure
      end

      private 
      
      def _configure
        return if @configured
        ::Resque.redis = Redis.connection
        ::Resque.redis.namespace = ENV.fetch('KMDB_REDIS_NS', 'kmdb:resque')
        ::Resque.logger.level = Logger::DEBUG
        @configured = true
      end
    end
    extend ModuleMethods
  end
end
