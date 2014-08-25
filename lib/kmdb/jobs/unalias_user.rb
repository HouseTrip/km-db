require 'kmdb'
require 'kmdb/models/user'
require 'kmdb/models/event'
require 'kmdb/models/property'
require 'kmdb/jobs/locked'

module KMDB
  module Jobs
    # Removes all references to a user alias
    class UnaliasUser < Locked
      @queue = :medium

      def self.perform(name1, name2)
        new(name1, name2).work
      end

      def initialize(name1, name2)
        @user  = User.where(name: name1).first
        @alias = User.where(name: name2).first
      end
      
      def work
        return unless @user && @alias
        [Property, Event].each do |model|
          model.where(user_id: @alias.id).update_all(user_id: @user.id)
        end
        @alias.destroy
      end
    end
  end
end

