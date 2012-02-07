require 'km/db/custom_record'
require 'km/db/belongs_to_user'

module KM::DB
  class Event < CustomRecord
    include BelongsToUser

    set_table_name "events"
    has_many   :properties, :class_name => 'KM::DB::Property'

    named_scope :with_properties, lambda { |*props|
      prop_table = Property.table_name
      selects = ["`#{table_name}`.*"]
      joins = []
      props.each_with_index { |prop,k|
        temp_name = "#{prop_table}_#{k}"
        selects << "`#{temp_name}`.`value` AS `#{prop.split.join('_')}`"
        joins << sanitize_sql_array([%Q{
          LEFT JOIN `properties` AS `#{temp_name}`
          ON `#{table_name}`.id = `#{temp_name}`.event_id 
          AND `#{temp_name}`.`key` = ?}, KM::DB::Key.get(prop)])
      }
      { :select => selects.join(', '), :joins => joins.join("\n") }
    }
    named_scope :before, lambda { |date| { :conditions => ["`t` < ?", date] } }
    named_scope :after,  lambda { |date| { :conditions => ["`t` > ?", date] } }

    named_scope :named, lambda { |name| { :conditions => { :n => KM::DB::Key.get(name) } } }

    named_scope :by_date, :order => '`t` ASC'

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
end
