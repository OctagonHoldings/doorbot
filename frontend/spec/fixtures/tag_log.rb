require 'dm-sweatshop'
require 'ffaker'

TagLog.fixture(:opened) {{
  card_type:   %w(clipper rfid)[rand(2)],
  card_number: /\d{10}/.gen,
  name:        FFaker::Name.name,
  created_at:  Time.now,
  door_opened: true,
}}

TagLog.fixture(:not_opened) {{
  card_type:   %w(clipper rfid)[rand(2)],
  card_number: /\d{10}/.gen,
  name:        FFaker::Name.name,
  created_at:  Time.now,
  door_opened: false,
}}

TagLog.fixture(:unknown) {{
  card_type:   %w(clipper rfid)[rand(2)],
  card_number: /\d{10}/.gen,
  name:        nil,
  created_at:  Time.now,
  door_opened: false,
}}
