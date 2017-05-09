class TagLog
  include DataMapper::Resource
  property :id,          Serial
  property :card_type,   String
  property :card_number, String, index: true
  property :name,        String, index: true
  property :created_at,  DateTime, index: true
  property :door_opened, Boolean
  property :held_tag,    Boolean

  before :create, :set_name_and_opened

  def associated_auth
    DoorAuthorization.first(card_number: card_number, card_type: card_type)
  end

  def door
    held_tag ? :rollup_door : :front_door
  end

  private

  def set_name_and_opened
    if associated_auth
      self.name = associated_auth.name
      self.door_opened = associated_auth.openable_doors.include?(door)
    else
      self.door_opened = false
    end
  end
end
