require 'kmdb/models/custom_record'

module KMDB
  # Aliasing events, ie. pairs of user names that are considered the same actual user.
  class Alias < ActiveRecord::Base
    self.primary_key = :id

    module ClassMethods
      def record(name1, name2, stamp)
        retries ||= 5
        name1, name2 = _sorted(name2, name1)
        where(name1: name1, name2: name2).first || create!(name1: name1, name2: name2, t: Time.at(stamp))
      rescue ActiveRecord::RecordNotUnique
        retry unless (retries -= 1).zero?
        raise
      end

      private

      # always the "lowest" name first, with preference to numeric names
      def _sorted(name1, name2)
        if name1 =~ /^[0-9]+$/
          [name1, name2]
        elsif name2 =~ /^[0-9]+$/
          [name2, name1]
        elsif name2 < name1
          [name2, name1]
        else
          [name1, name2]
        end
      end
    end
    extend ClassMethods
  end
end

