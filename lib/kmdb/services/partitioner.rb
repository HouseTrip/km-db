require 'kmdb'

module KMDB
  module Services
    class Partitioner
      def initialize(model:, min_date: nil, max_date: nil, days_per_partition: nil)
        @model              = model
        @min_date           = min_date           || Date.parse(ENV.fetch('KMDB_MIN_DATE'))
        @max_date           = max_date           || Date.parse(ENV.fetch('KMDB_MAX_DATE'))
        @days_per_partition = days_per_partition || Integer(ENV.fetch('KMDB_DAYS_PER_PARTITION'))
      end

      def run
        while true
          last_limit = _get_last_limit || @min_date
          break if last_limit > @max_date
          next_limit = last_limit + @days_per_partition
          _add_partition(next_limit)
        end
      end

      private

      def _get_last_limit
        limit = _conn.select_value(%Q{
          SELECT `partition_description` FROM information_schema.partitions
          WHERE `table_schema` = '#{_database_name}'
            AND `table_name` = '#{_table}'
            AND `partition_description` <> 'MAXVALUE'
          ORDER BY `partition_description` DESC LIMIT 1
        })
        limit ? Date.parse(limit) : nil
      end

      def _add_partition(date)
        part_limit = date.strftime("'%F'")
        part_name  = date.strftime('p%Y%m%d')
        _log "adding partition up to #{part_limit} to #{_table}"
        _conn.execute %Q{
          ALTER TABLE #{_table} REORGANIZE PARTITION pLast INTO (
            PARTITION #{part_name} VALUES LESS THAN (#{part_limit}),
            PARTITION pLast VALUES LESS THAN MAXVALUE
          )
        }
      end

      def _table
        @_table ||= @model.table_name
      end

      def _database_name
        @_database_name ||= _conn.current_database
      end

      def _conn
        @_conn ||= @model.connection
      end

      def _log(message)
        $stderr.write("#{message}\n")
      end

    end
  end
end
