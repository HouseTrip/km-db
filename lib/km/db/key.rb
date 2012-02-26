=begin

  Map strings (event and property names) to unique integers (Key#id) for performance

=end

require 'km/db/custom_record'

module KM::DB
  class Key < CustomRecord
    set_table_name "keys"

    has_many :events,     :foreign_key => :n,   :class_name => 'KM::DB::Event',    :dependent => :delete_all
    has_many :properties, :foreign_key => :key, :class_name => 'KM::DB::Property', :dependent => :delete_all

    named_scope :has_duplicate, lambda {
      {
        :select => "id, string, COUNT(id) AS quantity",
        :group => :string, :having => "quantity > 1"
      }
    }

    def self.get(string)
      @cache ||= {}
      @cache[string] ||= get_uncached(string)
    end

    # Replace each duplicate key ID with its most-used variant
    def self.fix_duplicates!
      has_duplicate.map(&:string).each do |string|
        all_keys = find(:all, :conditions => { :string => string })

        # sort keys by usage
        all_ids = all_keys.map { |key|
          [key.id, Event.named(key.id).count + Property.named(key.id).count]
        }.sort { |k1,k2|
          k1.second <=> k2.second
        }.map { |k|
          k.first
        }
        id_to_keep = all_ids.pop
        $stderr.write "Fixing key '#{string}' #{all_ids.inspect} -> #{id_to_keep.inspect}\n"
        Event.update_all({ :n => id_to_keep }, ["`events`.`n` IN (?)", all_ids])
        Property.update_all({ :key => id_to_keep }, ["`properties`.`key` IN (?)", all_ids])
        Key.delete_all(["id IN (?)", all_ids])
      end
    end

  private

    def self.get_uncached(string)
      string.size <= MaxStringSize or raise "String is too long"
      find_or_create(:string => string).id
    end
  end
end
