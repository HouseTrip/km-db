=begin

  Base class for KM data.
  Connect to a secondary database to store events, users, & properties.

  FIXME: the database connection is hard-coded for now.

=end


require 'active_record'
require 'erb'
require 'yaml'

class KM::DB::CustomRecord < ActiveRecord::Base
  # Connect to an alternate database when the class is loaded
  connect_to_km_db!

  DefaultConfig = {
    :adapter  => 'mysql2',
    :database => "km_events",
    :username => "root",
    :encoding => "utf8"
  }

  def self.disable_index
    connection.execute %Q{
      ALTER TABLE `#{table_name}` DISABLE KEYS;
    }
  end

  def self.enable_index
    connection.execute %Q{
      ALTER TABLE `#{table_name}` ENABLE KEYS;
    }
  end

  def self.find_or_create(options)
    find(:first, :conditions => options) || create(options)
  end

  def self.connect_to_km_db!
    config = YAML.load(ERB.new(File.open('config/km_db.yml').read).result)
    config.reverse_merge
    establish_connection(DefaultConfig.merge(config))

    unless connection.table_exists?('events')
      SetupEventsDatabase.up
      self.reset_column_information
    end
  end
end

