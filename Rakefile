require 'bundler'
require 'kmdb'

namespace :db do
  task :migrate do
    require 'kmdb'
    KMDB.connect.migrate
  end
end

