# Doorbot Frontend

## To make it go:

    gem install bundler
    bundle install
    ruby doorbot.rb &
    ruby guardian.rb &

## Production configuration

`scripts/start.sh` is a script that will run the code in the background on a raspberry pi. You can start it from cron or whatever.

## Testing

To run the tests, just run `rspec`

## If you want some fake data to play with:

    ruby fake_data.rb

## Put the following in your .env

    DOORBOT_ADMIN_USER=admin
    DOORBOT_ADMIN_PASSWORD=password
    DOORBOT_DB=doorbot.db
