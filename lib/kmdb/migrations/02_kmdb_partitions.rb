=begin
  
  Setup events and properties for partitioning

=end
require 'active_record'
require 'kmdb'

class KmdbPartitions < ActiveRecord::Migration

  def up
    sql = ""
    %w(events properties aliases).each do |t|
      sql << %Q{
        ALTER TABLE #{t} CHANGE id id BIGINT NOT NULL;
        ALTER TABLE #{t} DROP PRIMARY KEY;
        CREATE UNIQUE INDEX index_events_partition ON #{t} (t, id);
        CREATE INDEX index_events_id ON #{t} (id);
        ALTER TABLE #{t} CHANGE id id BIGINT NOT NULL AUTO_INCREMENT;
        ALTER TABLE #{t} PARTITION BY RANGE COLUMNS (t) (PARTITION pLast VALUES LESS THAN MAXVALUE);
      }
    end

    sql << %{
      ALTER TABLE `users`
        MODIFY `id` INT(11) NOT NULL,
        DROP PRIMARY KEY,
        ADD INDEX `index_users_id` (`id`);
      ALTER TABLE `users`	MODIFY `id` INT(11) NOT NULL AUTO_INCREMENT;
      ALTER TABLE `users` PARTITION BY KEY(`name`) PARTITIONS 32;
    }

    sql.strip.split(';').each { |stmt| execute stmt.strip }
  end

  def down
  end
end

