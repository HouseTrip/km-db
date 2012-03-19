require 'kmdb/belongs_to_user'

module KMDB
  class Property < CustomRecord
    include BelongsToUser

    set_table_name "properties"
    belongs_to :event, :class_name => 'KMDB::Event'

    default_scope :order => 't DESC'
    named_scope :named, lambda { |name| { :conditions => { :key => KMDB::Key.get(name) } } }

    def self.set(hash, stamp=nil, user=nil, event=nil)
      user_name = hash.delete('_p')
      user ||= User.get(user_name)
      raise UserError.new "User missing for '#{user_name}'" unless user.present?

      event_id = event ? event.id : nil
      stamp = Time.at hash.delete('_t') || stamp

      return if hash.empty?
      sql_insert = "INSERT INTO `#{table_name}` (`t`,`user_id`,`event_id`,`key`,`value`) VALUES "
      sql_values = []

      hash.each_pair do |prop_name,value|
        key = Key.get(prop_name)
        sql_values << sanitize_sql_array(["(?,?,?,?,?)", stamp,user.id,event_id,key,value])
      end

      connection.execute(sql_insert + sql_values.join(","))
    end
  end
end
