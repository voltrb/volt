# Run via rack server
require 'bundler/setup'
require 'volt/server'
run Volt::Server.new.app
