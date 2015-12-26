# Testing

## Installing the Requirements

You can install gem dependencies with bundler:

    $ gem install bundler
    $ bundler install

## Generate Documentation

    $ bundle exec rake doc

This will generate the HTML documentation in the `doc/` directory.

## Running the Syntax Style Tests

    $ bundle exec rake style

## Running the Unit Tests

Minitest tests can be run as usual:

    $ bundle exec rake unit
