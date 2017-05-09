class DoorAuthorization
  include DataMapper::Resource

  property :id,               Serial
  property :name,             String
  property :card_type,        String
  property :card_number,      String, key: true, unique: true
  property :expires_at,       DateTime
  property :created_at,       DateTime
  property :updated_at,       DateTime
  property :active,           Boolean, default: true
  property :can_open_rollup,  Boolean, default: false

  def expired?
    !expires_at.nil? && expires_at < DateTime.now
  end

  def openable_doors
    doors = []

    if active && !expired?
      doors << :front_door
      doors << :rollup_door if can_open_rollup
    end

    doors
  end
end
