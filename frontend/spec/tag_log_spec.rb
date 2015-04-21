require File.expand_path '../spec_helper.rb', __FILE__
require 'base64'

describe "Log" do
  context 'when not logged in' do

    it 'does not allow access to /admin/logs without a password' do
      get '/admin/logs'
      expect(last_response.status).to eq 401
      expect(last_response.header['WWW-Authenticate']).to eq 'Basic realm="Restricted Area"'
    end
  end

  context 'when logged in as an admin' do
    let(:rack_env) do
      {
        'HTTP_AUTHORIZATION' => "Basic #{Base64.encode64('admin:password').chomp}"
      }
    end

    before do
      ENV['DOORBOT_ADMIN_USER'] = 'admin'
      ENV['DOORBOT_ADMIN_PASSWORD'] = 'password'
    end

    it 'shows the log' do
      get '/admin/logs', {}, rack_env
      expect(last_response).to be_ok
    end
  end
end
