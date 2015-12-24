module Signaly
  class NotifyApp

    SNConfig = Struct.new(:sleep_seconds, # between checks
                      :remind_after, # the first notification
                      :notification_showtime,
                      :debug_output,
                      :login,
                      :password,
                      :url, # of the checked page
                      :skip_login,
                      :config_file,
                      :console_only,
                      :notify)

    DEFAULT_CONFIG_PATH = ".config/signaly-notify/config.yaml"

    def call(argv)
      options = process_options(argv)
      config = merge_structs(
        default_config,
        config_file(options.config_file),
        options
      )
      ask_config config

      notifier = Notifier.new
      prepare_outputters config, notifier

      check_loop config, notifier
    end

    private

    # load configuration from config file
    def config_file(path=nil)
      path ||= File.join ENV['HOME'], DEFAULT_CONFIG_PATH

      if File.exist? path then
        cfg = YAML.load(File.open(path))
        # symbolize keys
        cfg = cfg.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
        return cfg
      end

      return nil
    end

    def process_options(argv)
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

        opts.on "--notify NOTIFIER", "choose visual notification engine (possible values are 'libnotify' and 'growl')" do |s|
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
    def ask_config(config)
      cliio = HighLine.new
      config.login ||= cliio.ask("login: ")
      config.password ||= cliio.ask("password: ") {|q| q.echo = '*' }
    end

    # merges the config structs so that the last one
    # in the argument list has the highest priority and value nil is considered
    # empty
    def merge_structs(*structs)
      merged = structs.shift.dup

      merged.each_pair do |key, value|
        structs.each do |s|
          next if s.nil?
          if s[key] != nil then
            merged[key] = s[key]
          end
        end
      end

      return merged
    end

    def prepare_outputters(config, notifier)
      notifier.add_outputter ConsoleOutputter.new(config), :checked

      return if config.console_only
      return unless config.notify

      case config.notify.to_sym
      when :libnotify
        notifier.add_outputter LibNotifyOutputter.new(config), :changed, :remind
      when :growl
        notifier.add_outputter GrowlOutputter.new(config), :changed, :remind
      end
    end

    def check_loop(config, notifier)
      checker = Client.new config
      checker.login unless config.skip_login

      old_status = status = nil
      last_reminder = 0

      loop do
        old_status = status

        begin
          status = checker.user_status
        rescue Exception, SocketError => e
          STDERR.puts "#{e.class}: #{e.message}"
          sleep config.sleep_seconds
          retry
        end

        notifier.emit :checked, status, old_status

        if status > old_status then
          # something new
          notifier.emit :changed, status, old_status
          last_reminder = Time.now.to_i

        elsif config.remind_after != 0 &&
              Time.now.to_i >= last_reminder + config.remind_after &&
                                               status.is_there_anything? then
          # nothing new, but pending content should be reminded
          notifier.emit :remind, status, old_status
          last_reminder = Time.now.to_i
        end

        sleep config.sleep_seconds
      end
    end

    def default_config
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
      # use first available visual notification engine
      if defined? Libnotify
        defaults.notify = :libnotify
      elsif defined? Growl
        defaults.notify = :growl
      end
      return defaults
    end
  end
end
