require 'kmdb/models/custom_record'

module KMDB
  class Dumpfile < CustomRecord
    set_table_name 'dumpfiles'

    validates_presence_of :offset
    validates_presence_of :path

    def set(offset)
      update_attributes!(:offset => offset)
    end

    def offset
      attributes['offset'] || 0
    end

    def self.get(pathname, job = nil)
      job ||= 'nil'
      find_or_create(:path => pathname.cleanpath.to_s, :job => job)
    end
  end
end
