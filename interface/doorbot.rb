require 'sinatra'
require 'haml'

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
