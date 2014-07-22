=begin
  
  Setup events and properties for partitioning

=end
require 'active_record'
require 'kmdb'

class KmdbPartitions < ActiveRecord::Migration

  def up
    %w(events properties).each do |t|
      sql = %Q{
        ALTER TABLE #{t} CHANGE id id INT(11) NOT NULL
        ALTER TABLE #{t} DROP PRIMARY KEY
        CREATE UNIQUE INDEX index_events_partition ON #{t} (t, id)
        CREATE INDEX index_events_id ON #{t} (id)
        ALTER TABLE #{t} CHANGE id id INT(11) NOT NULL AUTO_INCREMENT
        ALTER TABLE #{t} PARTITION BY HASH (YEARWEEK(t)) PARTITIONS 52
      }
      sql.strip.split(/\n/).each { |stmt| execute stmt.strip }
    end
  end

  def down
  end
end

