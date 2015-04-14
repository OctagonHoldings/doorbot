require 'dm-sweatshop'
require 'ffaker'

DoorAuthorization.fixture(:active) {{
  name:        Faker::Name.name,
  card_type:   %w(clipper mifare)[rand(2)],
  card_number: /\d{10}/.gen,
  expires_at:  nil,
  created_at:  Time.now,
  updated_at:  Time.now,
  active:      true,
}}

DoorAuthorization.fixture(:inactive) {{
  name:        Faker::Name.name,
  card_type:   %w(clipper mifare)[rand(2)],
  card_number: /\d{10}/.gen,
  expires_at:  nil,
  created_at:  Time.now,
  updated_at:  Time.now,
  active:      true,
}}

DoorAuthorization.fixture(:expired) {{
  name:        Faker::Name.name,
  card_type:   %w(clipper mifare)[rand(2)],
  card_number: /\d{10}/.gen,
  expires_at:  Time.now - 10*86400,   # 10 days ago
  created_at:  Time.now,
  updated_at:  Time.now,
  active:      true,
}}
