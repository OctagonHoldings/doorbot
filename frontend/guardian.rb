require 'data_mapper'
require 'dm-sqlite-adapter'
require 'dotenv'
require 'pry'
require 'getoptlong'

reader_command = '../reader/report_tag'

opts = GetoptLong.new(
  [ '--test', '-t', GetoptLong::OPTIONAL_ARGUMENT]
)

gpio_command = 'gpio'

opts.each do |opt, arg|
  case opt
    when '--test'
      puts 'Test Mode'
      reader_command = '../reader/fake_tag.sh'
      ENV['DOORBOT_DB'] = 'test.db'
      gpio_command = 'true'
   end
end

Dotenv.load

DataMapper::Logger.new($stdout, :debug)
DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/#{ENV['DOORBOT_DB']}")

require_relative 'models/door_authorization'
require_relative 'models/tag_log'

DataMapper.finalize
DoorAuthorization.auto_upgrade!
TagLog.auto_upgrade!

`#{gpio_command} -g mode 9 out`

def check_process(handle, command)
  if handle.closed?
    return restart(command)
  end

  begin
    Process.kill(0, handle.pid)
  rescue Errno::ESRCH
    puts "Reader exited. Restarting."
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

tag_reporter = restart(reader_command)
Process.detach(tag_reporter.pid)

while(true) do
  tag_reporter = check_process(tag_reporter, reader_command)
  tag = tag_reporter.gets("\n")
  next unless tag =~ /\w/
  tag.chop!

  tag_log = {
    card_type: tag =~ /^c/ ? 'clipper' : 'rfid',
    card_number: tag
  }

  authorization = DoorAuthorization.first(card_number: tag)

  if authorization
    tag_log[:name] = authorization.name

    unless authorization.expired?
      tag_log[:door_opened] = true
    end
  end

  TagLog.create(tag_log)
  puts "Stored #{tag}"

  if tag_log[:door_opened]
    # open the door
    `#{gpio_command} -g write 9 1`
    sleep 0.25
    `#{gpio_command} -g write 9 0`
  end
end
