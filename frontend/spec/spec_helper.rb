# from: http://recipes.sinatrarb.com/p/testing/rspec

require 'rack/test'
require 'blue-shell'

ENV['DOORBOT_DB'] = 'test.db'

require File.expand_path '../../doorbot.rb', __FILE__

ENV['RACK_ENV'] = 'test'

module RSpecMixin
  include Rack::Test::Methods
  def app() Sinatra::Application end
end

RSpec.configure do |c|
  c.include RSpecMixin
  c.include BlueShell::Matchers
end
