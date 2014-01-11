# Run via rack server
require 'bundler/setup'
require 'volt/server'
run Server.new.app
