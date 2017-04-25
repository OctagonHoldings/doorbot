require 'data_mapper'
require 'dm-sqlite-adapter'
require 'dotenv'
require 'pry'

Dotenv.load

# DataMapper::Logger.new($stdout, :debug)
DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/doorbot.db")

require_relative 'models/door_authorization'
require_relative 'models/tag_log'

require_relative 'spec/fixtures/door_authorization'
require_relative 'spec/fixtures/tag_log'


# Perform basic sanity checks and initialize all relationships
# Call this when you've defined all your models
DataMapper.finalize

# automatically create the post table
DoorAuthorization.auto_upgrade!
TagLog.auto_upgrade!

3.times do
  DoorAuthorization.gen(:active)
  DoorAuthorization.gen(:inactive)
  DoorAuthorization.gen(:expired)

  TagLog.gen(:opened)
  TagLog.gen(:not_opened)
  TagLog.gen(:unknown)
end
