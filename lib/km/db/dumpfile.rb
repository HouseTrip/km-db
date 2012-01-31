require 'km/db/custom_record'

module KM::DB
  class Dumpfile < CustomRecord
    set_table_name "dumpfiles"

    validates_presence_of :basename
    validates_presence_of :last_line

    def set(lineno)
      update_attributes!(:last_line => lineno)
    end

    def last_line
      attributes['last_line'] || 0
    end

    def self.get(path, job = nil)
      basename = File.basename(path)
      basename += " @#{job.to_s}" if job
      find_or_create(:basename => basename)
    end
  end
end
