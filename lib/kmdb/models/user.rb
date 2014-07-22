require 'kmdb/models/custom_record'
require 'kmdb/concerns/has_properties'

module KMDB
  class User < ActiveRecord::Base
    include CustomRecord
    include HasProperties

    has_many :events,     class_name: 'KMDB::Event', inverse_of: :user
      # points to the aliased user. if set, no properties/events should belong to this user

    validates_presence_of   :name
    validates_uniqueness_of :name

    scope :named, lambda { |name| where(name: name) }

    # return (latest) value of property
    def prop(name)
      properties.named(name).first.andand.value
    end
  end
end
