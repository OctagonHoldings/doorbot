require 'sinatra'
require 'haml'
require 'data_mapper'
require 'dm-sqlite-adapter'

DataMapper::Logger.new($stdout, :debug)
DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/doorbot.db")

require_relative 'models/door_authorization'
require_relative 'models/tag_log'


# Perform basic sanity checks and initialize all relationships
# Call this when you've defined all your models
DataMapper.finalize

# automatically create the post table
DoorAuthorization.auto_upgrade!
TagLog.auto_upgrade!

helpers do
  def protected!
    return if authorized?
    headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
    halt 401, "Not authorized\n"
  end

  def authorized?
    @auth ||=  Rack::Auth::Basic::Request.new(request.env)
    @auth.provided? and @auth.basic? and @auth.credentials and @auth.credentials == ['admin', '0rbit']
  end
end

get '/' do
  haml :index, :format => :html5
end

get '/potatoes' do
  haml :potatoes, :format => :html5
end

get '/admin' do
  protected!
  haml :admin, :format => :html5
end

get '/admin/list' do
  protected!
  haml :list, :format => :html5
end
