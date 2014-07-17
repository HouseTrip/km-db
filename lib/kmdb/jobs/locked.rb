require 'kmdb'
require 'resque/plugins/lock'

module KMDB
  module Jobs
    class Locked
      extend ::Resque::Plugins::Lock
    end
  end
end
