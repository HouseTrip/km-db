require 'kmdb/models/custom_record'
require 'kmdb/concerns/belongs_to_user'
require 'kmdb/concerns/has_properties'
require 'kmdb/models/global_uid'
require 'kmdb/user_error'

module KMDB
  class Event < ActiveRecord::Base
    self.primary_key = :id

    include CustomRecord
    include BelongsToUser
    include HasProperties

    scope :before, lambda { |date| where("`#{table_name}`.`t` < ?", date) }
    scope :after,  lambda { |date| where("`#{table_name}`.`t` > ?", date) }

    scope :named, lambda { |name| where(n: KMDB::Key.get(name)) }

    scope :by_date, lambda { order("`#{table_name}`.`t` ASC") }

    # return value of property
    def prop(name)
      properties.named(name).first.andand.value
    end

    def name
      KMDB::Key.find(n).value
    end

    def self.sql_for(hash)
      user_name = hash.delete('_p')
      user = User.find_or_create(name: user_name)
      raise UserError.new "User missing for '#{user_name}'" unless user.present?

      stamp = Time.at hash.delete('_t')
      key = Key.get hash.delete('_n').scrub

      event_id = GlobalUID.get(:event)
      event_sql = sanitize_sql_array(["(?,?,?,?)", event_id, stamp, key, user.id])
      properties_sql = Property.sql_for(hash, stamp: stamp, user: user, event_id: event_id)
      
      yield event_sql, properties_sql
    end

    def self.mass_create(values_strings)
      return if values_strings.empty?
      sql_insert = "INSERT INTO `#{table_name}` (`id`, `t`, `n`, `user_id`) VALUES\n"
      connection.execute(sql_insert + values_strings.join(",\n"))
    end
  end
end
