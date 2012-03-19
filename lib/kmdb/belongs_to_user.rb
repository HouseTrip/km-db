module KMDB
  module BelongsToUser
    def self.included(mod)
      mod.class_eval do
        belongs_to :user,  :class_name => 'KMDB::User'
        validates_presence_of :user

        named_scope :user_is, lambda { |user| 
          user.kind_of?(User) or raise TypeError.new("Not a kind of User")
          { :conditions => { :user_id => user.id } }
        }
      end
    end
  end
end
