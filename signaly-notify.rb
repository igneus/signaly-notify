require 'rubygems'
require 'mechanize' # interaction with websites
require 'colorize' # colorful console output
require 'highline' # automating some tasks of the cli user interaction
require 'libnotify' # visual notification
require 'optparse'

login = ''
password = ''

SNConfig = Struct.new :sleep_seconds, :remind_after, :notification_showtime
config = SNConfig.new

# set config defaults:
# how many seconds between two checks of the site
config.sleep_seconds = 60
# if there is some pending content and I don't look at it,
# remind me after X seconds
config.remind_after = 60*5
# for how long time the notification shows up
config.notification_showtime = 10


# finds the first integer in the string and returns it
# or returns 0
def find_num(str)
  m = str.match /\d+/

  unless m
    return 0
  end

  return m[0].to_i
end

module Signaly
  # interaction with signaly.cz

  # takes user name and password; returns a page (logged-in) or throws
  # exception
  def Signaly.login(agent, login, password)
    page = agent.get('https://www.signaly.cz/')

    login_form = page.form_with(:action => '/?do=loginForm-submit')
    login_form['name'] = login
    login_form['password'] = password

    page = agent.submit(login_form)

    errors = page.search(".//div[@class='message-error']")
    if errors.size > 0 then
      msg = ''
      errors.each {|e| msg += e.text.strip+"\n" }
      raise "Login to signaly.cz failed: "+msg
    end

    return page
  end

  def Signaly.user_status(agent)
    status = {:pm => 0, :notifications => 0, :invitations => 0}
    page = agent.get('https://www.signaly.cz/')
    
    menu = page.search(".//div[@class='menu-user']")

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

    ms = new_status[:pm].to_s
    if changed?(new_status, old_status, :pm) then
      ms = ms.colorize(:red)
    end
    print "  messages: "+ms

    ns = new_status[:notifications].to_s
    if changed?(new_status, old_status, :notifications) then
      ns = ns.colorize(:red) 
    end
    print "  notifications: "+ns

    is = new_status[:invitations].to_s
    if changed?(new_status, old_status, :invitations) then
      is = is.colorize(:red)
    end
    puts "  invitations: "+is
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
    ms = status[:pm].to_s
    ns = status[:notifications].to_s
    is = status[:invitations].to_s
    text = "pm: #{ms}\nnotifications: #{ns}\ninvitations: #{is}"

    Libnotify.show(:body => text, :summary => "signaly.cz", :timeout => @config.notification_showtime)
  end
end

def changed?(new_status, old_status, item)
  (old_status == nil && new_status[item] > 0) ||
    (old_status != nil && new_status[item] != old_status[item])
end

# process options
optparse = OptionParser.new do |opts|
  opts.on "-u", "--user NAME", "user name used to log in" do |n|
    login = n
  end

  opts.on "-p", "--password WORD", "user's password" do |p|
    password = p
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

  opts.on "-h", "--help", "print this help" do
    puts opts
    exit 0
  end
end
optparse.parse!

unless ARGV.empty? 
  puts "Warning: unused commandline arguments: "+ARGV.join(', ')
end

# ask the user for missing essential information
cliio = HighLine.new

if login == '' then
  login = cliio.ask("login: ")
end

if password == '' then
  password = cliio.ask("password: ") {|q| q.echo = '*' }
end

# start interaction with the website
agent = Mechanize.new

page = Signaly.login agent, login, password

old_status = status = nil
last_reminder = 0

co = ConsoleOutputter.new config
lno = LibNotifyOutputter.new config

loop do
  old_status = status
  status = Signaly.user_status agent

  # print each update to the console:
  co.output status, old_status

  # send a notification only if there is something interesting:

  if old_status == nil ||
      (status[:pm] != old_status[:pm] || 
       status[:notifications] != old_status[:notifications]) then
    # something new
    lno.output status, old_status
    last_reminder = Time.now.to_i

  elsif config.remind_after != 0 &&
      Time.now.to_i >= last_reminder + config.remind_after then
    # nothing new, but pending content should be reminded
    lno.output status, old_status
    last_reminder = Time.now.to_i
  end

  sleep config.sleep_seconds
end
