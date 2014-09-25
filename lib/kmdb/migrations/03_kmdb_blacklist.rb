=begin
  
  Setup events and properties for partitioning

=end
require 'active_record'
require 'kmdb'

class KmdbBlacklist < ActiveRecord::Migration

  def up
    create_table :blacklisted_properties do |t|
      t.string :name
    end
  end

  def down
  end
end

