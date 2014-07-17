=begin
  
  Setup a custom database for KissMetrics tracking events.

=end
require 'active_record'
require 'kmdb'

class KmdbInitial < ActiveRecord::Migration

  def up
    create_table :events do |t|
      t.integer  :user_id
      t.integer  :n
      t.datetime :t
      t.integer  :tid
    end
    add_index :events, [:n],          using: :hash
    add_index :events, [:user_id],    using: :hash
    add_index :events, [:tid]


    create_table :keys do |t|
      t.string :string
    end
    add_index :keys, [:string],         using: :hash, unique: true

    create_table :properties do |t|
      t.integer  :user_id
      t.integer  :event_id
      t.integer  :key
      t.string   :value
      t.datetime :t
      t.integer  :tid # transaction ID
    end
    add_index :properties, [:key],      using: :hash
    add_index :properties, [:user_id],  using: :hash
    add_index :properties, [:event_id], using: :hash
    add_index :properties, [:t, :id],   unique: true # for partitioning purposes
    add_index :properties, [:tid]

    create_table :users do |t|
      t.string  :name
    end
    add_index :users, [:name],          using: :hash, unique: true

    create_table :ignored_users do |t|
      t.string :name
    end

    create_table :aliases do |t|
      t.string   :name1
      t.string   :name2
      t.datetime :t
    end
    add_index :aliases, [:name1, :name2], unique: true

    create_table :dumpfiles do |t|
      t.integer :revision
      t.integer :length
      t.integer :offset
      t.timestamps
    end
    add_index :dumpfiles, [:revision]
  end

  def down
    drop_table :events
    drop_table :properties
    drop_table :users
    drop_table :aliases
  end
end
