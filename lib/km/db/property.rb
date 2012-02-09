require 'km/db/belongs_to_user'

module KM::DB
  class Property < CustomRecord
    include BelongsToUser

    set_table_name "properties"
    belongs_to :event, :class_name => 'KM::DB::Event'

    default_scope :order => 't DESC'
    named_scope :named, lambda { |name| { :conditions => { :key => KM::DB::Key.get(name) } } }

    def self.set(hash, stamp=nil, user=nil, event=nil)
      user_name = hash.delete('_p')
      user ||= User.get(user_name)
      raise UserError.new "User missing for '#{user_name}'" unless user.present?

      event_id = event ? event.id : nil
      stamp = Time.at hash.delete('_t') || stamp

      transaction do
        hash.each_pair do |prop_name,value|
          key = Key.get(prop_name)
          connection.execute(sanitize_sql_array([%Q{
            INSERT INTO `#{table_name}` (`t`,`user_id`,`event_id`,`key`,`value`) VALUES (?,?,?,?,?)
          }, stamp,user.id,event_id,key,value]))
        end
      end
    end
  end
end
