require File.expand_path '../../spec_helper.rb', __FILE__
require 'base64'

require_relative '../../models/door_authorization'

require_relative '../../spec/fixtures/door_authorization'


describe DoorAuthorization do
  describe 'expired?' do
    it 'is true for expired auths' do
      auth = DoorAuthorization.gen(:expired)
      expect(auth.expired?).to eq true
    end

    it 'is false for unexpired auths' do
      auth = DoorAuthorization.gen(:active)
      expect(auth.expired?).to eq false
    end
  end
end
