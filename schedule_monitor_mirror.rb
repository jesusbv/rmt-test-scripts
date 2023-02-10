#!/usr/bin/env ruby

require 'date'

# Schedule a mirror process based on a config file and
# monitor the mirror process checking for errors
class ScheduleMonitorMirror
  def initialize(config_path)
    raise "#{config_path} does not exist or is not a file" unless File.exist?(config_path) and File.file?(config_path)

    @schedule_time = File.open(config_path).read
    @cron_file = '/etc/cron.d/mirror_schedule'
    # delete cron file when object is destroyed
    ObjectSpace.define_finalizer(self, proc { cleanup })
  end

  def schedule_mirror
    # time format expected
    # dd/mm/yyyy hh:mm
    # example every 5 min
    # */5 * * * * /bin/bash -c "foo"
    # add the time to cron
    # <time_format> /usr/bin/rmt-cli mirror"
    file = File.open(@cron_file)
    file.write(cron_entry)
    system `system cron reload`
  end

  def monitor
    mirror_errors = ''
    error_match = 'Mirroring completed with errors'
    while true
      lines = log_lines_after_scheduled
      mirror_errors = lines.any? { |line| line.include?(error_match) }
      if mirror_errors
        puts 'Mirroring errors found'
        return
      end
      mirror_ok = lines.any? { |line| line.include?('Mirroring completed.') }
      if mirror_ok
        puts 'No mirroring errors found'
        return
      end
      sleep 5.minutes
    end
  end

  def cleanup
    File.delete @cron_file
  end

  private

  def cron_entry
    date_time = DateTime.strptime(@schedule_time, '%d/%m/%Y %H:%M')
    "#{date_time.minute} #{date_time.hour} #{date_time.month} #{date_time.wday}  /usr/bin/rmt-cli mirror"
  end

  def log_lines_after_scheduled
    lines = File.readlines '/var/log/messages'
    scheduled_date = DateTime.strptime(@schedule_time, '%d/%m/%Y %H:%M')
    lines.each do |line, index|
      # line has the format
      # yyyy-mm-ddThh:m:ss.1234+00:00 server_host_name ....
      file_date = line.split[0] # get the time
      file_date = DateTime.rfc3339(file_date)
      return lines[index..] if file_date > schedule_date
    end
  end
end

config_path = ARGV[0]
schedule_monitor = ScheduleMonitorMirror.new(config_path)
schedule_monitor.schedule_mirror
schedule_monitor.monitor

