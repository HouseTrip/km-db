module KMDB
  MaxStringSize = 48

  %w(key user property event user_error dumpfile parser parallel_parser).each do |mod|
    require "kmdb/#{mod}"
  end

  # Connect to an alternate database when the module is loaded
  CustomRecord.connect_to_km_db!
end
