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
    run_guardian
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

  context 'when the card is just tagged' do
    let(:card_numbers) { ['t:538912432432'] }

    it 'pulls out the card number' do
      run_guardian
      tag = TagLog.last
      expect(tag.card_number).to eq '538912432432'
      expect(tag.card_type).to eq 'rfid'
      expect(tag.held_tag).to be_falsy
    end
  end

  context 'when the card held' do
    let(:card_numbers) { ['h:538912432432'] }

    it 'pulls out the card number, and sets the held flag' do
      run_guardian
      tag = TagLog.last
      expect(tag.card_number).to eq '538912432432'
      expect(tag.card_type).to eq 'rfid'
      expect(tag.held_tag).to be_truthy
    end
  end

  shared_examples 'access denied' do |user_name|
    before do
      run_guardian
      @tag = TagLog.last
    end

    it 'sets the name if it exists' do
      expect(@tag.name).to eq user_name
    end

    it 'does not open either door' do
      expect(@tag.is_authorized).to be_falsy
      expect(rollup_door_unlocked).to be_falsy
      expect(front_door_unlocked).to be_falsy
    end
  end

  context 'tagging a recognized card' do
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
      expect(tag.is_authorized).to eq true
      expect(front_door_unlocked).to be_truthy
      expect(front_door_relocked).to be_truthy
    end

    it 'does not open the rollup' do
      run_guardian
      expect(rollup_door_unlocked).to be_falsy
    end

    context 'when the account is inactive' do
      let(:active) { false }
      include_examples 'access denied', 'Bob'
    end

    context 'when the account is expired' do
      let(:expires_at) { Time.now - 86400 * 3 }  # 3 days
      include_examples 'access denied', 'Bob'
    end
  end

  context 'holding a recognized card' do
    let(:active) { true }
    let(:expires_at) { nil }
    let(:card_numbers) { ['h:538912432432'] }
    let(:card_number_for_auth) { '538912432432' }

    context 'with rollup access' do
      before do
        DoorAuthorization.create(
          name:            'Claude Cahun',
          card_type:       'rfid',
          card_number:     card_number_for_auth,
          created_at:      Time.now,
          updated_at:      Time.now,
          expires_at:      expires_at,
          active:          active,
          can_open_rollup: true
        )
      end

      it 'fetches the name and logs it' do
        run_guardian
        tag = TagLog.last
        expect(tag.name).to eq 'Claude Cahun'
      end

      it 'opens the rollup door, and then resets the relay' do
        run_guardian
        tag = TagLog.last
        expect(tag.is_authorized).to eq true
        expect(tag.held_tag).to be_truthy

        expect(rollup_door_unlocked).to be_truthy
        expect(rollup_door_relocked).to be_truthy
      end

      it 'does not open the front door' do
        run_guardian
        expect(front_door_unlocked).to be_falsy
      end

      context 'when the account is inactive' do
        let(:active) { false }

        include_examples 'access denied', 'Claude Cahun'
      end
    end

    context 'without rollup access' do
      before do
        DoorAuthorization.create(
          name:            'Cindy Sherman',
          card_type:       'rfid',
          card_number:     card_number_for_auth,
          created_at:      Time.now,
          updated_at:      Time.now,
          expires_at:      expires_at,
          active:          active,
          can_open_rollup: false
        )
      end

      include_examples 'access denied', 'Cindy Sherman'
    end
  end

  context 'with an unrecognized card' do
    include_examples 'access denied', nil
  end

  context 'when the tag reader process exits' do
    it 'restarts it' do
      pending 'check that the subprocess gets restarted'
      expect(ProcessRestart).to have_been_called
    end
  end

  def run_guardian &block
    BlueShell::Runner.run guardian do |runner|
      runner.with_timeout(2) do
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
    gpio_commands.select { |command| command =~ /write (9|10)/ }
  end

  def front_door_unlocked
    lock_commands.include?('-g write 9 0')
  end

  def front_door_relocked
    lock_commands.last == '-g write 9 1'
  end

  def rollup_door_unlocked
    lock_commands.include?('-g write 10 0')
  end

  def rollup_door_relocked
    lock_commands.last == '-g write 10 1'
  end
end
