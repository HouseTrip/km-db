require 'pathname'
require 'progressbar'
require 'oj'
require 'kmdb/models/dumpfile'

module KMDB
  class Parser
    class ProgressBar < ::ProgressBar
      attr_writer :title
    end
    
    attr :resume_job
    attr :verbose
    attr :abort_on_error

    def initialize(options = {})
      @processed_bytes = nil
      @total_bytes = nil
      @exclude_regexps = []
      @include_regexps = []
      @filters = []
      @verbose        = options.delete(:verbose)
      @resume_job     = options.delete(:resume)
      @abort_on_error = options.delete(:abort_on_error)

      if @resume_job && @verbose && Dumpfile.count > 0
        log "Using restart information"
      end
    end

    def exclude(regexp)
      @exclude_regexps << regexp
      self
    end

    def only(regexp)
      @include_regexps << regexp
      self
    end

    def add_filter(&block)
      @filters << block
      self
    end

    def run(argv)
      inputs = list_files_in(argv)
      total_bytes = total_size_of_files(inputs)
      log "total bytes : #{total_bytes}"
      total_bytes -= inputs.map { |p| Dumpfile.get(p, @resume_job) }.compact.map(&:offset).sum
      log "left to process : #{total_bytes}"
      
      @processed_bytes = 0
      @progress = ProgressBar.new("-" * 20, total_bytes)
      @progress.long_running if @progress.respond_to?(:long_running)
      
      inputs.sort.each do |input|
        process_events_in_file(input)
      end

      @progress.finish
    end

  private

    def log(message)
      $stderr.write(message + "\n") if @verbose
    end

    def process_event(text)
      return if @exclude_regexps.any? { |re| text =~ re }
      return unless @include_regexps.all? { |re| text =~ re }

      # filter strange utf-8 encoding/escaping found in KM dumps   
      if text =~ /\\30[3-5]\\[0-9]{3}/
        begin
          text = eval("%Q(#{text})") 
        rescue SyntaxError => e
          log "Syntax error in: #{text}"
          raise e if @abort_on_error
        end
      end

      begin
        data = Oj.load(text)
      rescue Oj::ParseError => e
        log "Warning, JSON parse error in: #{text}"
        raise e if @abort_on_error
        return
      end

      if data.nil?
        log "Warning, JSON parse failed in: #{text}"
        return
      end

      @filters.each do |filter|
        data = filter.call(text, data) or break
      end
    end

    def process_events_in_file(pathname)
      pathname.open do |input|
        @progress.title = pathname.basename.to_s
        if @resume_job
          dumpfile = Dumpfile.get(pathname, @resume_job)
          log "Starting file #{pathname} from offset #{dumpfile.offset}"
          input.seek(dumpfile.offset)
        end
        line_number = 0
        while line = input.gets
          @processed_bytes += line.size
          @progress.set @processed_bytes if line_number % 100 == 0
          line_number += 1

          process_event(line)
          dumpfile.set(input.tell) if @resume_job
        end
      end
    end

    def total_size_of_files(inputs)
      inputs.map { |c| c.stat.size }.inject(0) { |a,b| a+b }
    end

    def list_files_in_directory(directory)
      input_fns = []
      directory.find do |input_pn|
        input_pn.to_s =~ /\.json$/ or next
        input_fns << input_pn
      end
      input_fns.sort
    end

    def list_files_in(argv)
      argv.map { |arg| Pathname.new(arg) }.map { |pn|
        pn.exist? and pn or raise "No such file or directory '#{pn}'"
      }.map { |pn|
        pn.directory? ? list_files_in_directory(pn) : pn
      }.flatten
    end
  end
end
