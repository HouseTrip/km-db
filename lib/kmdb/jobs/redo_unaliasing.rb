require 'kmdb'
require 'kmdb/resque'
require 'kmdb/models/alias'
require 'kmdb/jobs/locked'
require 'kmdb/jobs/unalias_user'
require 'time'

module KMDB
  module Jobs
    # Processes recent unalias user events, again
    # This copes with parallelism in the import process
    class RedoUnaliasing < Locked
      @queue = :low

      def self.perform(date)
        new(date).work
      end

      def initialize(date)
        @date = Date.parse(date)
      end
      
      def work
        Alias.where('t BETWEEN ? AND ?', @date, @date.next).find_each do |aliaz|
          Resque.enqueue(UnaliasUser, aliaz.name1, aliaz.name2)
        end
      end
    end
  end
end

