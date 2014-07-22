require 'kmdb'

module KMDB
  # can be injected into any ActiveRecord model
  # with a +name+ attribute and few records (up to a few hundreds)
  module TableRegexp
    def regexp
      @_regexp ||= begin
        all_res = all.to_a.map { |iu| Regexp.new('^%s$' % Regexp.escape(iu.name)) }
        all_res.empty? ? :empty : Regexp.union(*all_res)
      end
    end
  end
end
