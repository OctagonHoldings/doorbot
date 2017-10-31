require 'dm-sweatshop'
require 'ffaker'

DoorAuthorization.fixture(:active_without_rollup) {{
  name:            FFaker::Name.name,
  card_type:       %w(clipper mifare)[rand(2)],
  card_number:     /\d{10}/.gen,
  expires_at:      nil,
  created_at:      Time.now,
  updated_at:      Time.now,
  active:          true,
  can_open_rollup: false
}}

DoorAuthorization.fixture(:active_with_rollup) {{
  name:            FFaker::Name.name,
  card_type:       %w(clipper mifare)[rand(2)],
  card_number:     /\d{10}/.gen,
  expires_at:      nil,
  created_at:      Time.now,
  updated_at:      Time.now,
  active:          true,
  can_open_rollup: true
}}

DoorAuthorization.fixture(:inactive) {{
  name:        FFaker::Name.name,
  card_type:   %w(clipper mifare)[rand(2)],
  card_number: /\d{10}/.gen,
  expires_at:  nil,
  created_at:  Time.now,
  updated_at:  Time.now,
  active:      false,
}}

DoorAuthorization.fixture(:expired) {{
  name:        FFaker::Name.name,
  card_type:   %w(clipper mifare)[rand(2)],
  card_number: /\d{10}/.gen,
  expires_at:  Time.now - 10*86400,   # 10 days ago
  created_at:  Time.now,
  updated_at:  Time.now,
  active:      true,
}}
