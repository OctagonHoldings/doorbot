#!/usr/bin/env ruby

require 'sinatra'
require 'haml'
require 'data_mapper'
require 'dm-sqlite-adapter'
require 'dotenv'
require 'pry'
require 'sinatra/flash'
require 'warden'

enable :sessions

Dotenv.load

DataMapper::Logger.new($stdout, :debug)
DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/#{ENV['DOORBOT_DB']}")

require_relative 'models/door_authorization'
require_relative 'models/tag_log'
require_relative 'models/user'

DataMapper.finalize
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
    @auth.provided? and @auth.basic? and @auth.credentials and @auth.credentials == [ENV['DOORBOT_ADMIN_USER'], ENV['DOORBOT_ADMIN_PASSWORD']]
  end
end

get '/' do
  haml :index, format: :html5
end

get '/potatoes' do
  haml :potatoes, format: :html5
end

get '/admin' do
  protected!
  haml :admin, format: :html5
end

get '/admin/list' do
  protected!
  @authorizations = DoorAuthorization.all(:order => [:name.asc])
  haml :list, format: :html5
end

get '/admin/logs' do
  protected!
  @tags = TagLog.all(:order => [:created_at.desc])
  haml :logs, format: :html5
end

get '/admin/edit' do
  protected!
  if params[:from_tag]
    tag = TagLog.get(params[:from_tag])
    @authorization = DoorAuthorization.first(card_number: tag.card_number)

    auth_data = {
      name: tag.name,
      card_type: tag.card_type,
      card_number: tag.card_number
    }
  elsif params[:authorization]
    auth_data = params[:authorization]
  elsif params[:auth_id]
    @authorization = DoorAuthorization.first(id: params[:auth_id])
    auth_data = {}
  else
    auth_data = {}
  end
  @authorization ||= DoorAuthorization.new(auth_data)
  haml :authorization_form, format: :html5
end

delete '/admin/delete' do
  protected!
  @authorization = DoorAuthorization.first(id: params[:auth_id])
  if @authorization && @authorization.destroy
    flash[:notice] = "Deleted #{@authorization.name}."
  end
  redirect '/admin/list'
end

post '/admin/authorizations' do
  protected!
  auth_data = params[:authorization]
  auth_data[:active] = auth_data[:active] == 'on' ? true : false
  auth_data[:expires_at] = auth_data[:expires_at] == '' ? nil : Date.parse(auth_data[:expires_at])
  @authorization = DoorAuthorization.first(id: params[:id]) if params[:id]

  unless @authorization.nil?
    @authorization.update(auth_data)
  else
    @authorization = DoorAuthorization.create(auth_data)
  end
  haml :authorization_confirmation, format: :html5
end

use Warden::Manager do |config|
  config.serialize_into_session{|user| user.id }
  config.serialize_from_session{|id| User.get(id) }

  config.scope_defaults :default,
    strategies: [:password],
    # The action is a route to send the user to when
    # warden.authenticate! returns a false answer. We'll show
    # this route below.
    action: 'auth/unauthenticated'

  # When a user tries to log in and cannot, this specifies the
  # app to send the user to.
  config.failure_app = self
end

Warden::Manager.before_failure do |env,opts|
  env['REQUEST_METHOD'] = 'POST'
end

Warden::Strategies.add(:password) do
  def valid?
    params['user']['name'] && params['user']['password']
  end

  def authenticate!
    user = User.first(username: params['user']['name'])

    if user.nil?
      fail!("The username you entered does not exist.")
    elsif user.authenticate(params['user']['password'])
      success!(user)
    else
      fail!("Could not log in")
    end
  end
end
