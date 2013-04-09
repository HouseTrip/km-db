require 'kmdb/custom_record'
require 'kmdb/belongs_to_user'
require 'kmdb/has_properties'
require 'active_support/all' # pulls in timezone stuff (plus lots more)

module KMDB
  class Event < CustomRecord
    include BelongsToUser
    include HasProperties

    set_table_name "events"

    named_scope :before, lambda { |date| { :conditions => ["`#{table_name}`.`t` < ?", date] } }
    named_scope :after,  lambda { |date| { :conditions => ["`#{table_name}`.`t` > ?", date] } }

    named_scope :named, lambda { |name| { :conditions => { :n => KMDB::Key.get(name) } } }

    named_scope :by_date, lambda { { :order => "`#{table_name}`.`t` ASC" } }

    # return value of property
    def prop(name)
      properties.named(name).first.andand.value
    end

    def name
      KMDB::Key.find(n).value
    end

    def self.record(hash)
      user_name = hash.delete('_p')
      user ||= User.get(user_name)
      raise UserError.new "User missing for '#{user_name}'" unless user.present?

      Time.zone ||= 'UTC'
      stamp = Time.zone.at hash.delete('_t')
      key = Key.get hash.delete('_n')
      event = create(:t => stamp, :n => key, :user => user)
      Property.set(hash, stamp, user, event)
    end
  end
end
