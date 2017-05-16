require 'dm-sweatshop'
require 'ffaker'

TagLog.fixture(:opened) {{
  card_type:   %w(clipper rfid)[rand(2)],
  card_number: /\d{10}/.gen,
  name:        FFaker::Name.name,
  created_at:  Time.now,
  is_authorized: true,
}}

TagLog.fixture(:not_opened) {{
  card_type:   %w(clipper rfid)[rand(2)],
  card_number: /\d{10}/.gen,
  name:        FFaker::Name.name,
  created_at:  Time.now,
  is_authorized: false,
}}

TagLog.fixture(:opened_with_hold) {{
  card_type:   %w(clipper rfid)[rand(2)],
  card_number: /\d{10}/.gen,
  name:        FFaker::Name.name,
  created_at:  Time.now,
  is_authorized: true,
  held_tag:    true,
}}

TagLog.fixture(:unknown) {{
  card_type:   %w(clipper rfid)[rand(2)],
  card_number: /\d{10}/.gen,
  name:        nil,
  created_at:  Time.now,
  is_authorized: false,
}}
