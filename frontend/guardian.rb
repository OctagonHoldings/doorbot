require 'data_mapper'
require 'dm-sqlite-adapter'
require 'dotenv'
require 'pry'
require 'getoptlong'

prog = '../reader/report_tag'

opts = GetoptLong.new(
  [ '--test', '-t', GetoptLong::OPTIONAL_ARGUMENT]
)

opts.each do |opt, arg|
  case opt
    when '--test'
      puts 'Test Mode'
      prog = '../reader/fake_tag.sh'
      ENV['DOORBOT_DB'] = 'test.db'
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

tag_reporter = IO.popen(prog)

while(true) do
  tag = tag_reporter.gets("\n").chop

  tag_log = {
    card_type: tag =~ /^c/ ? 'clipper' : 'rfid',
    card_number: tag
  }

  TagLog.create(tag_log)
  puts "Stored #{tag}"
end
