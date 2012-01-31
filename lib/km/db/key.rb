# Map strings (event and property names) to unique integers (Key#id) for performance
class KM::DB::Key < KM::DB::CustomRecord
  set_table_name "keys"

  has_many :events,     :foreign_key => :n,   :class_name => 'KM::Event',    :dependent => :delete_all
  has_many :properties, :foreign_key => :key, :class_name => 'KM::Property', :dependent => :delete_all

  def self.get(string)
    @cache ||= {}
    @cache[string] ||= get_uncached(string)
  end

  # Replace each duplicate key ID with its most-used variant
  def self.fix_duplicates!
    find(:all, :group => :string).map(&:string).each do |string|
      # find keys for this string
      all_keys = find(:all, :conditions => { :string => string })
      next unless all_keys.size > 1

      # sort keys by usage
      all_ids = all_keys.map { |key|
        [key.id, Event.named(key.id).count + Property.named(key.id).count]
      }.sort { |k1,k2|
        k1.second <=> k2.second
      }.map { |k|
        k.first
      }
      id_to_keep = all_ids.pop
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

