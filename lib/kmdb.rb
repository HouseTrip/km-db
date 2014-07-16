require 'active_record'

module KMDB
  DEFAULT_DB_URL = 'sqlite3:test.db'
  MIGRATIONS_DIR = Pathname(__FILE__).parent.join('kmdb/migrations').cleanpath.to_s

  module ModuleMethods
    def env
      ENV['RACK_ENV'] || ENV['KMDB_ENV'] || 'development'
    end

    def connect
      url = ENV.fetch('DATABASE_URL', DEFAULT_DB_URL)
      puts url
      ActiveRecord::Base.establish_connection(url)

      if ENV.fetch('KMDB_AR_LOG', 'NO') == 'YES'
        ActiveRecord::Base.logger = ActiveSupport::Logger.new(STDOUT)
      end
      self
    end

    def migrate
      ActiveRecord::Migration.verbose = true
      ActiveRecord::Migrator.migrate MIGRATIONS_DIR
      self
    end

    def transaction(&block)
      ActiveRecord::Base.transaction(&block)
    end
  end
  extend ModuleMethods
end
