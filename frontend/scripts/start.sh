#!/usr/bin/env bash

cd /home/pi/doorbot/frontend

export PATH=$PATH:/home/pi/.rbenv/shims:/usr/local/bin

bundle exec doorbot.rb -o 0.0.0.0 -p 8080 2>&1 | logger -t doorbot-web &
bundle exec guardian.rb 2>&1 | logger -t doorbot-guardian &
