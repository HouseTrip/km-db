require 'json/ext'
require 'pathname'
require 'progressbar'
require 'pstore'

module KM::DB
  class Parser
    class ProgressBar < ::ProgressBar
      attr_writer :title
    end
    
    attr :use_restart
    attr :verbose
    attr :abort_on_error

    def initialize(options = {})
      @processed_bytes = nil
      @total_bytes = nil
      @exclude_regexps = []
      @include_regexps = []
      @filters = []
      @verbose = options.delete(:verbose)
      @use_restart = options.delete(:use_restart)
      @abort_on_error = options.delete(:abort_on_error)

      if @use_restart && @verbose && Dumpfile.count > 0
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

      @processed_bytes = 0
      @progress = ProgressBar.new("-" * 20, total_bytes)

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
      if text =~ /\\303\\[0-9]{3}/
        begin
          preparsed_text = eval("%Q(#{text})") 
        rescue SyntaxError => e
          log "Syntax error in: #{text}"
          raise e if @abort_on_error
        end
      else
        preparsed_text = text
      end

      begin
        data = JSON.parse(text)
      rescue JSON::ParserError => e
        log "Warning, JSON parse error in: #{text}"
        raise e if @abort_on_error
      end

      @filters.each do |filter|
        data = filter.call(text, data) or break
      end
    end

    def process_events_in_file(input)
      @progress.title = input.basename.to_s
      dumpfile = Dumpfile.get(input, @use_restart) if @use_restart
      line_number = 0
      input.each_line do |event|
        @processed_bytes += event.size
        @progress.set @processed_bytes if line_number % 100 == 0
        line_number += 1

        next if @use_restart && line_number <= dumpfile.last_line
        process_event(event)
        dumpfile.set(line_number) if @use_restart
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
