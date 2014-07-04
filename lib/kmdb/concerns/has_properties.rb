=begin

  KMDB::HasProperties --

  Trait shared by Event and User.

=end
require 'kmdb/models/property'
require 'kmdb/models/key'

module KMDB
  module HasProperties
    def self.included(mod)
      mod.class_eval do
        has_many :properties, :class_name => 'KMDB::Property'

        # scope :with_properties, lambda { |*props|
        #   direction = props.delete(:exclude_missing) ? 'INNER' : 'LEFT'
        #   prop_table = Property.table_name
        #   selects = ["`#{table_name}`.*"]
        #   joins = []
        #   props.each_with_index { |prop,k|
        #     temp_name = "#{prop_table}_#{k}"
        #     selects << "`#{temp_name}`.`value` AS `#{prop.split.join('_')}`"
        #     joins << sanitize_sql_array([%Q{
        #       #{direction} JOIN `properties` AS `#{temp_name}`
        #       ON `#{table_name}`.id = `#{temp_name}`.event_id 
        #       AND `#{temp_name}`.`key` = ?}, KMDB::Key.get(prop)])
        #   }
        #   { :select => selects.join(', '), :joins => joins.join("\n") }
        # }
      end
    end
  end
end
