class KM::DB::Event < CustomRecord
  include BelongsToUser

  set_table_name "events"
  has_many   :properties, :class_name => 'KM::Property'
  named_scope :with_property, lambda { |prop|
    prop_table = Property.table_name
    { 
      :select => "`#{table_name}`.*, `#{prop_table}`.`value` AS `#{prop}`",
      :joins => sanitize_sql_array(["INNER JOIN `properties` ON `#{table_name}`.id = `#{prop_table}`.event_id AND `properties`.`key` = ?", prop])
    }
  }
  named_scope :with_properties, lambda { |*props|
    prop_table = Property.table_name
    selects = ["`#{table_name}`.*"]
    joins = []
    props.each_with_index { |prop,k|
      temp_name = "#{prop_table}_#{k}"
      selects << "`#{temp_name}`.`value` AS `#{prop.split.join('_')}`"
      joins << sanitize_sql_array([%Q{
        INNER JOIN `properties` AS `#{temp_name}`
        ON `#{table_name}`.id = `#{temp_name}`.event_id 
        AND `#{temp_name}`.`key` = ?}, prop])
    }
    { :select => selects.join(', '), :joins => joins.join("\n") }
  }

  named_scope :named, lambda { |name| { :conditions => { :n => name } } }

  # return value of property
  def prop(name)
    properties.named(name).first.andand.value
  end

  def self.record(hash)
    user_name = hash.delete('_p')
    user ||= User.get(user_name)
    raise UserError.new "User missing for '#{user_name}'" unless user.present?

    stamp = Time.at hash.delete('_t')
    key = Key.get hash.delete('_n')

    transaction do
      connection.execute(sanitize_sql_array([%Q{
        INSERT INTO `#{table_name}` (`t`,`n`,`user_id`) VALUES (?,?,?)
      }, stamp,key,user.id]))

      Property.set(hash, stamp, user, last)
    end
  end
end
