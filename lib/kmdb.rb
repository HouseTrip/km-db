require 'kmdb/models/custom_record'

module KMDB
  MaxStringSize = 255

  def self.connect
    CustomRecord.connect_to_km_db!
  end
end
