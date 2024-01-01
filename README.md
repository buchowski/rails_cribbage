# README

This is a Rails wrapper for https://github.com/buchowski/ruby-cribbage

## Development

* bundle install
* sudo service postgresql start
* rails s

## Database Fixtures

* Run rails db:fixtures:load to load the database with *.yml data in the test/fixtures directory
* Rspec tests use the fixture data in the spec/fixtures directory

## Tests

* rails t
* rails test:system
* rspec
