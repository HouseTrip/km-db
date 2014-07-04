=begin
  
  Setup a custom database for KissMetrics tracking events.

=end
require 'active_record'
require 'kmdb'
require 'kmdb/models/custom_record'

module KMDB
  class SetupEventsDatabase < ActiveRecord::Migration
    def self.connection
      CustomRecord.connection
    end

    def self.up
      create_table :events do |t|
        t.integer  :user_id
        t.integer  :n
        t.datetime :t
      end
      add_index :events, [:n],          using: 'hash'
      add_index :events, [:user_id],    using: 'hash'


      create_table :keys do |t|
        t.string :string, :limit => MaxStringSize
      end
      add_index :keys, [:string],         using: 'hash'

      create_table :properties do |t|
        t.integer  :user_id
        t.integer  :event_id
        t.integer  :key
        t.string   :value,   :limit => 64
        t.datetime :t
      end
      add_index :properties, [:key],      using: 'hash'
      add_index :properties, [:user_id],  using: 'hash'
      add_index :properties, [:event_id], using: 'hash'

      create_table :users do |t|
        t.string  :name, :limit => 48
        t.integer :alias_id
      end
      add_index :users, [:name]

      create_table :dumpfiles do |t|
        t.string  :path
        t.string  :job
        t.integer :offset
      end
      add_index :dumpfiles, [:path]

    end

    def self.down
      drop_table :events
      drop_table :properties
      drop_table :users
      drop_table :aliases
    end
  end
end
