#!/usr/bin/env ruby

require 'data_mapper'
require 'dm-sqlite-adapter'
require 'dotenv'
require 'pry'
require 'getoptlong'

def check_process(handle, command)
  if handle.closed?
    return restart(command)
  end

  begin
    Process.kill(0, handle.pid)
  rescue Errno::ESRCH
    sleep 3  # if it crashes right away, don't go crazy
    return restart(command)
  end

  handle
end

def restart(command)
  tag_reporter = IO.popen(command)
  Process.detach(tag_reporter.pid)
  puts "Started reader, pid #{tag_reporter.pid}"
  return tag_reporter
end

def close_door(gpio_command, door)
  `#{gpio_command} -g write #{DOOR_PINS[door]} 1`
end

def open_door(gpio_command, door)
  `#{gpio_command} -g write #{DOOR_PINS[door]} 0`
end

$stdout.sync = true

reader_command = '../reader/report_tag'
gpio_command = 'gpio'

DOOR_PINS = {
  front_door: 9,
  rollup_door: 10
}

opts = GetoptLong.new(
  [ '--test', '-t', GetoptLong::OPTIONAL_ARGUMENT]
)

opts.each do |opt, arg|
  case opt
    when '--test'
      puts 'Test Mode'
      reader_command = arg.empty? ? '../reader/fake_tag.sh' : arg
      ENV['DOORBOT_DB'] = 'test.db'
      gpio_command = './spec/scripts/fake_gpio.sh'
  end
end

Dotenv.load

# DataMapper::Logger.new($stdout, :debug)
DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/#{ENV['DOORBOT_DB']}")

require_relative 'models/door_authorization'
require_relative 'models/tag_log'

DataMapper.finalize
DoorAuthorization.auto_upgrade!
TagLog.auto_upgrade!

close_door(gpio_command, :front_door)
`#{gpio_command} -g mode 9 out`
close_door(gpio_command, :front_door)

close_door(gpio_command, :rollup_door)
`#{gpio_command} -g mode 10 out`
close_door(gpio_command, :rollup_door)

# spare relay. off.
`#{gpio_command} -g write 11 1`
`#{gpio_command} -g mode 11 out`


tag_reporter = restart(reader_command)
Process.detach(tag_reporter.pid)

while(true) do
  tag_reporter = check_process(tag_reporter, reader_command)
  tag = tag_reporter.gets("\n")
  next unless tag =~ /\w/
  tag.chop!

  if tag =~ /(\w+):(.*)/
    flag = $1
    tag = $2
  end

  tag_log = TagLog.create(
    card_type: tag =~ /^c/ ? 'clipper' : 'rfid',
    card_number: tag,
    held_tag: flag == 'h' ? true : false
  )

  if tag_log.is_authorized
    open_door(gpio_command, tag_log.door)
    sleep 0.1
    close_door(gpio_command, tag_log.door)
  end
end
