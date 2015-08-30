#!/bin/env ruby

require 'mechanize' # interaction with websites
require 'colorize' # colorful console output
require 'highline' # automating some tasks of the cli user interaction
require 'libnotify' # visual notification
require 'optparse'
require 'yaml'

SNConfig = Struct.new(:sleep_seconds, # between checks
                      :remind_after, # the first notification
                      :notification_showtime,
                      :debug_output,
                      :login,
                      :password,
                      :url, # of the checked page
                      :skip_login)

# merges the config structs so that the last one
# in the argument list has the highest priority and value nil is considered
# empty
def merge_structs(*structs)
  merged = structs.first.dup

  merged.each_pair do |key, value|
    k = key.to_s # a sym normally; but we also want to merge a normal Hash received from Yaml
    structs.each do |s|
      if s[k] != nil then
        merged[k] = s[k]
      end
    end
  end
end

# how many PMs, notifications, invitations a user has at a time
class SignalyStatus < Struct.new(:pm, :notifications, :invitations)

  def initialize(pm=0, notifications=0, invitations=0)
    super(pm, notifications, invitations)
  end

  def is_there_anything?
    self.each_pair {|k,v| return true if v > 0 }
    return false
  end

  # does self have anything new compared with other?
  def >(other)
    [:pm, :notifications, :invitations].each do |prop|
      if send(prop) > other.send(prop) then
        return true
      end
    end

    return false
  end

  # is there any change between old_status and self in property prop?
  def changed?(old_status, prop)
    (old_status == nil && self[prop] > 0) ||
      (old_status != nil && self[prop] != old_status[prop])
  end
end

# interaction with signaly.cz
class SignalyChecker

  def initialize(config)
    @username = config.login
    @password = config.password

    @agent = Mechanize.new

    @dbg_print_pages = config.debug_output || false # print raw html of all request results?

    @checked_page = config.url || 'https://www.signaly.cz/'
  end

  USERMENU_XPATH = ".//div[contains(@class, 'section-usermenu')]"

  # takes user name and password; returns a page (logged-in) or throws
  # exception
  def login
    page = @agent.get(@checked_page)
    debug_page_print "front page", page

    login_form = page.form_with(:id => 'frm-loginForm')
    unless login_form
      raise "Login form not found on the index page!"
    end
    login_form['name'] = @username
    login_form['password'] = @password

    page = @agent.submit(login_form)
    debug_page_print "first logged in", page

    errors = page.search(".//div[@class='alert alert-error']")
    if errors.size > 0 then
      msg = ''
      errors.each {|e| msg += e.text.strip+"\n" }
      raise "Login to signaly.cz failed: "+msg
    end

    usermenu = page.search(USERMENU_XPATH)
    if usermenu.empty? then
      raise "User-menu not found. Login failed or signaly.cz UI changed again."
    end

    return page
  end

  def user_status
    status = SignalyStatus.new
    page = @agent.get(@checked_page)
    debug_page_print "user main page", page

    menu = page.search(USERMENU_XPATH)

    pm = menu.search(".//a[@href='/vzkazy']")
    status[:pm] = find_num(pm.text)

    notif = menu.search(".//a[@href='/ohlasky']")
    status[:notifications] = find_num(notif.text)

    inv = menu.search(".//a[@href='/vyzvy']")
    if inv then
      status[:invitations] = find_num(inv.text)
    end

    return status
  end

  private

  def debug_page_print(title, page)
    return if ! @dbg_print_pages

    STDERR.puts
    STDERR.puts ("# "+title).colorize(:yellow)
    STDERR.puts
    STDERR.puts page.search(".//div[@class='navbar navbar-fixed-top section-header']")
    STDERR.puts
    STDERR.puts "-" * 60
    STDERR.puts
  end

  # finds the first integer in the string and returns it
  def find_num(str, default=0)
    m = str.match /\d+/

    unless m
      return default
    end

    return m[0].to_i
  end
end

class SignalyStatusOutputter
  def initialize(config)
    @config = config
  end

  def output(new_status, old_status)
  end
end

class ConsoleOutputter < SignalyStatusOutputter
  def output(new_status, old_status)
    print_line new_status, old_status
    set_console_title new_status
  end

  private

  def print_line(new_status, old_status)
    t = Time.now

    puts # start on a new line
    print t.strftime("%H:%M:%S")

    [:pm, :notifications, :invitations].each do |what|
      num = new_status[what].to_s
      if new_status.changed?(old_status, what) then
        num = num.colorize(:red)
      end
      print "  #{what}: #{num}"
    end
    puts
  end

  # doesn't work....
  def set_console_title(status)
    t = "signaly-notify: #{status[:pm]}/#{status[:notifications]}"
    `echo -ne "\\033]0;#{t}\\007"`
  end
end

class LibNotifyOutputter < SignalyStatusOutputter
  def output(new_status, old_status)
    send_notification new_status
  end

  private

  def send_notification(status)
    text = [:pm, :notifications, :invitations].collect do |what|
      "#{what}: #{status[what]}"
    end.join "\n"

    Libnotify.show(:body => text, :summary => "signaly.cz", :timeout => @config.notification_showtime)
  end
end


############################################# main

# set config defaults:
defaults = SNConfig.new
# how many seconds between two checks of the site
defaults.sleep_seconds = 60
# if there is some pending content and I don't look at it,
# remind me after X seconds
defaults.remind_after = 60*5
# for how long time the notification shows up
defaults.notification_showtime = 10
defaults.debug_output = false
defaults.password = nil

# find default config file
config_file = nil
default_config_path = File.join ENV['HOME'], ".config/signaly-notify/config.yaml"
if default_config_path then
  config_file = default_config_path
end

# process options
config = SNConfig.new
optparse = OptionParser.new do |opts|
  opts.on "-u", "--user NAME", "user name used to log in" do |n|
    config.login = n
  end

  opts.on "-p", "--password WORD", "user's password" do |p|
    config.password = p
  end

  opts.separator "If you don't provide any of the options above, "\
  "the program will ask you to type the name and/or password on its start. "\
  "(And especially "\
  "for the password it's probably a bit safer to type it this way than "\
  "to type it on the commandline.)\n\n"

  opts.on "-s", "--sleep SECS", Integer, "how many seconds to sleep between two checks (default is #{config.sleep_seconds})" do |s|
    config.sleep_seconds = s
  end

  opts.on "-r", "--remind SECS", Integer, "if I don't bother about the contents I recieved a notification about, remind me after X seconds (default is #{config.remind_after}; set to 0 to disable)" do |s|
    config.remind_after = s
  end

  opts.on "-d", "--debug", "print debugging information to STDERR" do
    config.debug_output = true
  end

  opts.on "--url URL", "check URL different from the default (for developmeng)" do |s|
    config.url = s
  end

  opts.on "--skip-login", "don't login (for development)" do
    config.skip_login = true
  end

  opts.on "-h", "--help", "print this help" do
    puts opts
    exit 0
  end

  opts.on "-c", "--config FILE", "configuration file" do |f|
    config_file = f
  end
end
optparse.parse!

# apply configuration
config_layers = []
config_layers << defaults
if config_file then
  config_layers << YAML.load(File.open(config_file))
end
config_layers << config

config = merge_structs(*config_layers)

unless ARGV.empty?
  puts "Warning: unused commandline arguments: "+ARGV.join(', ')
end

# ask the user for missing essential information
cliio = HighLine.new
config.login ||= cliio.ask("login: ")
config.password ||= cliio.ask("password: ") {|q| q.echo = '*' }

checker = SignalyChecker.new config
checker.login unless config.skip_login

old_status = status = nil
last_reminder = 0

co = ConsoleOutputter.new config
lno = LibNotifyOutputter.new config

loop do
  old_status = status

  begin
    status = checker.user_status
  rescue Exception, SocketError => e
    Libnotify.show(:body => "#{e.class}: #{e.message}",
                   :summary => "signaly.cz: ERROR",
                   :timeout => 20)
    sleep config.sleep_seconds
    retry
  end

  # print each update to the console:
  co.output status, old_status

  # send a notification only if there is something interesting:

  if old_status == nil || status > old_status then
    # something new
    lno.output status, old_status
    last_reminder = Time.now.to_i

  elsif config.remind_after != 0 &&
      Time.now.to_i >= last_reminder + config.remind_after &&
      status.is_there_anything? then
    # nothing new, but pending content should be reminded
    lno.output status, old_status
    last_reminder = Time.now.to_i
  end

  sleep config.sleep_seconds
end
