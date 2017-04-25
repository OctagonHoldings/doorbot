#!/usr/bin/env bash

cd /home/pi/doorbot/frontend

export PATH=$PATH:/home/pi/.rbenv/shims:/usr/local/bin

bundle exec maintenance.rb 2>&1 | logger -t doorbot-maintenance
