require 'resque/server'
require 'kmdb/resque'

KMDB::Resque.configure

run Rack::URLMap.new \
  '/resque' => Resque::Server.new

