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

tag_reporter = IO.popen(reader_command)

`#{gpio_command} mode 17 out`

while(true) do
  tag = tag_reporter.gets("\n").chop

  tag_log = {
    card_type: tag =~ /^c/ ? 'clipper' : 'rfid',
    card_number: tag
  }

  authorization = DoorAuthorization.first(card_number: tag)

  if authorization
    tag_log[:name] = authorization.name

    unless authorization.expired?
      # open the door here.
      tag_log[:door_opened] = true
      `#{gpio_command} write 17 1`
    end
  end

  TagLog.create(tag_log)
  puts "Stored #{tag}"
end
