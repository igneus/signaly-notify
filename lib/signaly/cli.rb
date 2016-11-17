require 'highline'
require 'optparse'
require 'yaml'

module Signaly
  # collects configuration, starts NotifyApp
  class CLI
    DEFAULT_CONFIG_PATH = "#{ENV['HOME']}/.config/signaly-notify/config.yaml"

    def call(argv)
      options = process_options(argv)
      config = Config.default
               .merge(config_file(options.config_file))
               .merge(options)
      config = config.merge(find_available_notifier) if config.notify.nil?
      request_config config unless config.skip_login

      Signaly::NotifyApp.new.call config
    end

    private

    def process_options(argv)
      config = Config.new
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

        opts.on "--notify NOTIFIER", "choose visual notification engine (possible values: libnotify|growl|notifysend)" do |s|
          config.notify = s.to_sym
        end

        opts.on "--console-only", "don't display any visual notifications" do
          config.console_only = true
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
          config.config_file = f
        end
      end
      optparse.parse! argv


      unless argv.empty?
        STDERR.puts "Warning: unused commandline arguments: "+ARGV.join(', ')
      end

      return config
    end

    # ask the user for missing essential information
    def request_config(config)
      cliio = HighLine.new
      config.login ||= cliio.ask("login: ")
      config.password ||= cliio.ask("password: ") {|q| q.echo = '*' }
    end

    # load configuration from config file
    def config_file(path=nil)
      path ||= DEFAULT_CONFIG_PATH

      if File.exist? path then
        cfg = YAML.load(File.open(path))
        # symbolize keys
        cfg = cfg.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
        return cfg
      end

      return nil
    end

    def find_available_notifier
      config = Signaly::Config.new

      begin
        require 'libnotify'

        config.notify = :libnotify
        return config
      rescue LoadError
      end

      begin
        require 'ruby-growl'

        config.notify = :growl
        return config
      rescue LoadError
      end

      return config
    end
  end
end
