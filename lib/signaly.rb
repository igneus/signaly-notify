require 'mechanize'
require 'colorize'
require 'highline'
require 'optparse'
require 'yaml'

# optional gems for visual notifications
begin
  require 'libnotify'
rescue LoadError
end

begin
  require 'ruby-growl'
rescue LoadError
end


%w(
client
notifier
notify_app
status_outputter
status
).each {|l| require_relative "signaly/#{l}" }
