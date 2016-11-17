module Signaly
  class NotifyApp
    def call(config)
      notifier = Notifier.new
      prepare_outputters config, notifier

      check_loop config, notifier
    end

    private

    def prepare_outputters(config, notifier)
      notifier.add_outputter Signaly::ConsoleOutputter.new(config), :checked

      return if config.console_only
      return unless config.notify

      case config.notify.to_sym
      when :libnotify
        notifier.add_outputter Signaly::LibnotifyOutputter.new(config), :changed, :remind
      when :growl
        notifier.add_outputter Signaly::GrowlOutputter.new(config), :changed, :remind
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
  end
end
