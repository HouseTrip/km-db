require 'kmdb/models/custom_record'
require 'kmdb/concerns/belongs_to_user'
require 'kmdb/models/blacklisted_property'
require 'kmdb/user_error'

module KMDB
  class Property < ActiveRecord::Base
    self.primary_key = :id

    include CustomRecord
    include BelongsToUser

    belongs_to :event, class_name: 'KMDB::Event'

    scope :named, lambda { |name| where(key: KMDB::Key.get(name)) }

    def self.sql_for(hash, stamp: nil, user: nil, event_id: nil)
      user_name = hash.delete('_p')
      user ||= User.find_or_create(name: user_name)
      raise UserError.new "User missing for '#{user_name}'" unless user.present?

      stamp = Time.at hash.delete('_t') || stamp
      return if hash.empty?

      sql_values = []

      hash.each_pair do |prop_name,value|
        next if BlacklistedProperty.include?(prop_name)
        key = Key.get(prop_name)
        value = value[0...255].scrub
        sql_values << sanitize_sql_array(['(?,?,?,?,?)', stamp,user.id,event_id,key,value])
      end

      return if sql_values.empty?
      sql_values.join(",\n")
    end

    def self.mass_create(values_strings)
      return if values_strings.empty?
      sql_insert = "INSERT INTO `#{table_name}` (`t`,`user_id`,`event_id`,`key`,`value`) VALUES\n"
      connection.execute(sql_insert + values_strings.join(",\n"))
    end
  end
end
