require 'kmdb/models/custom_record'
require 'kmdb/migration'

module KMDB
  MaxStringSize = 255

  DefaultConfig = {
    'adapter'  => 'sqlite3',
    'database' => 'test.db'
  }


  def self.connect
    config = DefaultConfig.dup
    ['km_db.yml', 'config/km_db.yml'].each do |config_path|
      next unless File.exist?(config_path)
      config.merge! YAML.load(ERB.new(File.open(config_path).read).result)
      break
    end
    puts config.inspect
    ActiveRecord::Base.establish_connection(config)

    unless ActiveRecord::Base.connection.table_exists?('events')
      Migration::SetupEventsDatabase.up
      reset_column_information
    end
  end
end
