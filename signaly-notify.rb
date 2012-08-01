require 'rubygems'
require 'mechanize' # interaction with websites
require 'colorize' # colorful console output
require 'highline' # automating some tasks of the cli user interaction
require 'optparse'

login = ''
password = ''

sleep_seconds = 60

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
    status = {:pm => 0, :notifications => 0}
    page = agent.get('https://www.signaly.cz/')
    
    menu = page.search(".//div[@class='menu-user']")

    pm = menu.search(".//a[@href='/vzkazy']")
    status[:pm] = find_num(pm.text)

    notif = menu.search(".//a[@href='/ohlasky']")
    status[:notifications] = find_num(notif.text)

    return status
  end
end

def output(new_status, old_status=nil)
  t = Time.now

  notify = false
  notify = true if old_status == nil 

  puts # start on a new line
  print "#{t.hour}:#{t.min}:#{t.sec} "

  ms = new_status[:pm].to_s
  if (old_status == nil && new_status[:pm] > 0) ||
      (old_status != nil && new_status[:pm] != old_status[:pm]) then
    ms = ms.colorize(:red)
    notify = true
  end
  print "messages: "+ms

  ns = new_status[:notifications].to_s
  if (old_status == nil && new_status[:notifications] > 0) ||
      (old_status != nil && new_status[:notifications] != old_status[:notifications])
    ns = ms.colorize(:red) 
    notify = true
  end
  puts " notifications: "+ns
end

# doesn't work....
def set_console_title(status)
  t = "signaly-notify: #{status[:pm]}/#{status[:notifications]}"
  `echo -ne "\\033]0;#{t}\\007"`
end

def send_notification(status)
  ms = status[:pm].to_s
  ns = status[:notifications].to_s
  `notify-send "pm: #{ms} notifications: #{ns} / signaly.cz"`
end

# process options
optparse = OptionParser.new do |opts|
  opts.on "-l", "--login NAME", "user name used to log in" do |n|
    login = n
  end

  opts.on "-p", "--password WORD", "user's password" do |p|
    password = p
  end

  opts.on "-s", "--sleep SECS", Integer, "how many seconds to sleep between two checks (default is #{sleep_seconds})" do |s|
    sleep_seconds = s
  end

  opts.on "-h" "--help", "print this help" do
    puts opts
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

loop do
  status = Signaly.user_status agent

  output status, old_status
  set_console_title status
  if old_status == nil ||
      (status[:pm] != old_status[:pm] || 
       status[:notifications] != old_status[:notifications]) then
    send_notification status
  end

  old_status = status

  sleep sleep_seconds
end
