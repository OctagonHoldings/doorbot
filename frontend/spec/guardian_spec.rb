require File.expand_path '../spec_helper.rb', __FILE__

describe 'Guardian' do
  let(:guardian) { "ruby guardian.rb -t" }
  let(:card_numbers) { ['43127890423'] }
  let(:test_file) { "/tmp/guardian-test-numbers" } # this is also in fake_tag.sh
  let(:test_gpio_file) { '/tmp/guardian-test-gpio'}

  before do
    # put the card number where we can find it.
    File.open(test_file, 'w') do |f|
      f.write("#{card_numbers.join("\n")}\n")
      f.close()
    end
    File.unlink(test_gpio_file) if File.exist?(test_gpio_file)

    # this doesn't happen automatically.
    DoorAuthorization.destroy
    TagLog.destroy
  end

  after do
    TagLog.all.each(&:destroy!)
    File.unlink(test_file)
    File.unlink(test_gpio_file) if File.exist?(test_gpio_file)
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
    let(:active) { true }
    let(:expires_at) { nil }

    before do
      DoorAuthorization.create(
        name: 'Bob',
        card_type: 'rfid',
        card_number: card_numbers.first,
        created_at: Time.now,
        updated_at: Time.now,
        expires_at: expires_at,
        active: active
      )
    end

    it 'fetches the name and logs it' do
      run_guardian
      tag = TagLog.last
      expect(tag.name).to eq 'Bob'
    end

    it 'opens the door, and then locks it again' do
      run_guardian
      tag = TagLog.last
      expect(tag.door_opened).to eq true
      expect(door_unlocked).to be_truthy
      expect(door_relocked).to be_truthy
    end

    context 'when the account is inactive' do
      let(:active) { false }

      it 'sets the name, but does not open the door' do
        run_guardian
        tag = TagLog.last
        expect(tag.name).to eq 'Bob'
        expect(tag.door_opened).to be_falsy
        expect(door_unlocked).to be_falsy
      end
    end

    context 'when the account is expired' do
      let(:expires_at) { Time.now - 86400 * 3 }  # 3 days

      it 'sets the name, but does not open the door' do
        run_guardian
        tag = TagLog.last
        expect(tag.name).to eq 'Bob'
        expect(tag.door_opened).to be_falsy
        expect(door_unlocked).to be_falsy
      end
    end
  end

  context 'with an unrecognized card' do
    it 'does not open the door' do
      run_guardian
      tag = TagLog.last
      expect(tag).to be
      expect(tag.door_opened).to be_falsy
      expect(door_unlocked).to be_falsy
    end
  end

  context 'when the tag reader process exits' do
    it 'restarts it' do
      pending 'check that the subprocess gets restarted'
      expect(ProcessRestart).to have_been_called
    end
  end

  def run_guardian &block
    BlueShell::Runner.run guardian do |runner|
      runner.with_timeout(1) do
        expect(runner).to say "Started reader"
        yield runner if block
        begin
          runner.wait_for_exit
        rescue Timeout::Error
        end
      end
    end
  end

  def gpio_commands
    return unless File.file?(test_gpio_file)
    File.open(test_gpio_file, 'r') do |f|
      f.read.split("\n")
    end
  end

  def lock_commands
    gpio_commands.select { |command| command =~ /write 9/ }
  end

  def beep_commands
    gpio_commands.select { |command| command =~ /write 11/ }
  end

  def door_unlocked
    lock_commands.include?('-g write 9 0')
  end

  def door_relocked
    lock_commands.last == '-g write 9 1'
  end
end
