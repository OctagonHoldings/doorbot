require File.expand_path '../spec_helper.rb', __FILE__
require 'base64'

describe "Doorbot" do
  it "has a homepage" do
    get '/'
    expect(last_response).to be_ok
  end

  it "has a potatoes" do
    get '/potatoes'
    expect(last_response).to be_ok
  end

  context 'when not logged in' do
    it 'does not allow access to /admin without a password' do
      get '/admin'
      expect(last_response.status).to eq 401
      expect(last_response.header['WWW-Authenticate']).to eq 'Basic realm="Restricted Area"'
    end

    it 'does not allow access to /admin/list without a password' do
      get '/admin/list'
      expect(last_response.status).to eq 401
      expect(last_response.header['WWW-Authenticate']).to eq 'Basic realm="Restricted Area"'
    end

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

    it 'allows admin access' do
      get '/admin', {}, rack_env
      expect(last_response).to be_ok
    end

    it 'allows access to /admin/list' do
      get '/admin/list', {}, rack_env
      expect(last_response).to be_ok
    end

    it 'shows tag logs on /admin/logs' do
    end

  end

end
