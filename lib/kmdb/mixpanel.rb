# Base64 Encoded

# https://mixpanel.com/docs/api-documentation/importing-events-older-than-31-days

module KMDB
  class Mixpanel
    @key = 'foo'
    @host = 'http://api.mixpanel.com/import/'

=begin
{   "event": "game", 
    "properties": {
        "distinct_id": "50479b24671bf", 
        "ip": "123.123.123.123", 
        "token": "e3bc4100330c35722740fb8c6f5abddc", 
        "time": 1245613885, 
        "action": "play"
        
    }
}
=end

    def self.record(event)

    end

=begin
https://mixpanel.com/docs/integration-libraries/using-mixpanel-alias
https://mixpanel.com/docs/managing-users/assigning-your-own-unique-identifiers-to-users

{
"event": "$create_alias",
"properties": {
    "alias": "123"
    "distinct_id": "123456789ABCDEF0=="
    "time": 1362068619,
    "token": "our-token"
    }
}
=end
    def self.alias(user)
      # todo

      puts "User " + user.name + " is aliased to " + KMDB::User.find(user.alias_id).name unless user.alias_id == nil

=begin
      props = {
        :alias => user1,
        :distinct_id => user2,
        :time => time,
        :token => @key
      }
=end
      json = {
        :event => "$create_alias", 
        :properties => props
      }

      puts Base64.encode64(json.to_json)

    end

=begin
https://mixpanel.com/docs/people-analytics/people-http-specification-insert-data

The currently available actions that you may send us are $set, $add and $append.
These correspond to the set, increment and track_charge functions in our JS library.
{
    "$set": {
        "$first_name": "John",
        "$last_name": "Smith"
    },
    "$token": "36ada5b10da39a1347559321baf13063",
    "$distinct_id": "13793"
    "$ip": "123.123.123.123"
}
  
=end

    def self.set(stamp, data, user_name)
      # todo
    end

  end
end
