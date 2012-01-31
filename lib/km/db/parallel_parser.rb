#!/usr/bin/env ruby
=begin
    
    Read KissMetrics' event dump -- using parallel processes.

=end

require 'json/ext'
require 'pathname'
require 'progressbar'
require 'parallel'
require 'tempfile'


class KM::ParallelParser < KM::Parser
  
  def initialize(options = {})
    super(options)
    @worker_count = Parallel.processor_count
  end

  def run(argv)
    @pipe_rd, @pipe_wr = IO.pipe

    inputs = list_files_in(argv)
    total_bytes = total_size_of_files(inputs)

    # Start workers
      log "Using #{@worker_count} workers."
    Process.fork do
      @pipe_rd.close
      Parallel.each(inputs, :in_processes => @worker_count) do |input|
        KM::Event.connection.reconnect!
        # log "Worker #{Process.pid} starting #{input}"
        $0 = "worker: #{input}"
        process_events_in_file(input)
        # log "Worker #{Process.pid} done"
        true
      end
    end

    # Start gatherer
    $0 = "gatherer: #{$0}"
    @pipe_wr.close
    byte_counter = 0
    log "Starting gatherer, total bytes: #{total_bytes}"
    progress = ProgressBar.new("-" * 20, total_bytes)
    while line = @pipe_rd.gets
      if line =~ /^OK (\d+)$/
        byte_counter += $1.to_i
        progress.set byte_counter
      elsif line =~ /^FILE (.*)$/
        progress.title = $1
      else
        log "Unparsed line: '#{line}'"
      end
    end
    progress.finish
    log "Total bytes processed: #{byte_counter}"
    Process.waitall
  end

private

  def process_events_in_file(input)
    processed_bytes = 0
    dumpfile = KM::Dumpfile.get(input)
    line_number = 0
    @pipe_wr.write "FILE #{input.basename}\n"
    input.each_line do |event|
      line_number += 1
      processed_bytes += event.size

      next if line_number <= dumpfile.last_line
      process_event(event)
      dumpfile.set(line_number)

      if processed_bytes > 10_000
        @pipe_wr.write "OK #{processed_bytes}\n"
        processed_bytes = 0
      end

    end
    @pipe_wr.write "OK #{processed_bytes}\n"
  end

end

