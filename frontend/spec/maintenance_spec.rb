require File.expand_path '../spec_helper.rb', __FILE__

describe 'Maintenance' do
  let(:maintenance) { "ruby maintenance.rb -t" }

  before do
    # this doesn't happen automatically.
    DoorAuthorization.destroy
    TagLog.destroy
  end

  after do
    TagLog.all.each(&:destroy!)
  end

  context 'TagLog maintenance' do
    before do
      TagLog.create(
        card_type: 'clipper',
        card_number: 'c1234567',
        name: 'Foo Guy',
        door_opened: true,
        created_at: Date.today
      )

      TagLog.create(
        card_type: 'clipper',
        card_number: 'c1234567',
        name: 'Older Foo Guy',
        door_opened: true,
        created_at: Date.today - 31
      )
    end

    it 'removes old TagLog entries after 30 days' do
      run_maintenance do |runner|
        expect(runner).to say "Removed old TagLog entries"
      end
      tag = TagLog.last
      expect(tag.name).to eq 'Foo Guy'
      expect(TagLog.all.length).to eq 1
    end
  end

  def run_maintenance &block
    BlueShell::Runner.run maintenance do |runner|
      runner.with_timeout(1) do
        expect(runner).to say "Starting maintenance"
        yield runner if block
        begin
          runner.wait_for_exit
        rescue Timeout::Error
        end
      end
    end
  end
end
