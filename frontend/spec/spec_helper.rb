# from: http://recipes.sinatrarb.com/p/testing/rspec

require 'rack/test'

require File.expand_path '../../doorbot.rb', __FILE__

ENV['RACK_ENV'] = 'test'

module RSpecMixin
  include Rack::Test::Methods
  def app() Sinatra::Application end
end

# For RSpec 2.x
RSpec.configure { |c| c.include RSpecMixin }
