require 'kmdb/models/custom_record'
require 'kmdb/concerns/has_properties'

module KMDB
  class User < ActiveRecord::Base
    include CustomRecord
    include HasProperties

    self.table_name = "users"

    has_many :events,     :class_name => 'KMDB::Event'
    belongs_to :alias,    :class_name => 'KMDB::User' 
      # points to the aliased user. if set, no properties/events should belong to this user

    validates_presence_of   :name
    validates_uniqueness_of :name

    scope :named, lambda { |name| where(name: name) }

    scope :duplicates, lambda {
      select('id, COUNT(id) AS quantity').
      group(:name).
      having("quantity > 1")
    }

    # return (latest) value of property
    def prop(name)
      properties.named(name).first.andand.value
    end

    # mark this user as aliasing another
    def aliases!(other)
      [Property,Event].each do |model|
        model.user_is(self).update_all(user_id: other.id)
      end
      self.update_attributes!(:alias => other)
    end

    # return the user named `name` (creating it if necessary)
    # if `name` is an alias, return the original user
    def self.get(name)
      user = named(name).first || create(:name => name)
      user = user.alias while user.alias
      return user
    end


    # mark the two names as pointing to the same user
    def self.alias!(name1, name2)
      u1 = get(name1)
      u2 = get(name2)
      $stderr.write "Warning: user '#{user.name}' has an alias\n" if u1.alias
      $stderr.write "Warning: user '#{user.name}' has an alias\n" if u2.alias
      
      # nothing to do if both names already point to the same user
      return if u1 == u2  

      u2.aliases! u1
    end


    # duplication can occur during parallel imports because we're not running transactionally.
    def self.fix_duplicates!
      duplicates.map(&:name).each do |name|
        named(name).all.tap do |all_users|
          kept_user = all_users.pop
          all_users.each do |user|
            user.aliases! kept_user
            user.destroy
          end
        end
      end
    end


    # detect alias chains
    def self.resolve_alias_chains!
      joins(:alias).where('aliases_users.alias_id IS NOT NULL').find_each do |user|
        user = find(user.id)
        origin = find(user.alias_id)
        origin = origin.alias while origin.alias # go up the chain
        $stderr.write "Aliasing #{user.name} -> #{origin.name}\n"
        user.aliases!(origin)
      end
    end
  end
end
