require File.expand_path '../spec_helper.rb', __FILE__

describe 'Guardian' do
  let(:guardian) { 'ruby guardian.rb -t' }
  let(:card_numbers) { ['43127890423'] }
  let(:test_file) { "/tmp/guardian-test-numbers" } # this is also in fake_tag.sh

  it 'exits cleanly' do
  end

  before do
    # put the card number where we can find it.
    File.open(test_file, 'w') do |f|
      f.write("#{card_numbers.join("\n")}\n")
      f.close()
    end
  end

  after do
    TagLog.all.each(&:destroy!)
    File.unlink(test_file)
  end

  it 'stores the card number' do
    run_guardian do |runner|
      expect(runner).to say "Stored #{card_numbers.first}"
    end
    tag = TagLog.last
    expect(tag.card_number).to eq card_numbers.first
  end

  context 'with a clipper card' do
    let(:card_numbers) { ['c42317894123'] }

    it 'sets the card type to clipper' do
      run_guardian
      tag = TagLog.last
      expect(tag.card_type).to eq 'clipper'
    end
  end

  context 'with a non-clipper card' do
    let(:card_numbers) { ['538912432432'] }

    it 'sets the default card type' do
      run_guardian
      tag = TagLog.last
      expect(tag.card_type).to eq 'rfid'
    end
  end

  context 'with a recognized card' do
    it 'fetches the name and logs it'

    it 'opens the door'
  end

  context 'with an unrecognized card' do
    it 'does not open the door'
  end

  def run_guardian &block
    BlueShell::Runner.run guardian do |runner|
      runner.with_timeout(1) do
        yield runner if block
        begin
          runner.wait_for_exit
        rescue Timeout::Error
        end
      end
    end
  end

end
