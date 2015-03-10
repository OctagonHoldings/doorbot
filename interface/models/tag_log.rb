class TagLog
  include DataMapper::Resource
  property :id,          Serial
  property :card_type,   String
  property :card_number, String, index: true
  property :name,        String, index: true
  property :created_at,  DateTime, index: true
  property :door_opened, Boolean
end
