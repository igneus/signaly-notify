module Signaly
  class NotifyApp
    def call(config)
      client = Client.new config
      client.login unless config.skip_login

      observables = Observables.new client, config

      observables.all_states.subscribe Signaly::ConsoleOutputter.new(config)

      if config.notify && !config.console_only
        outputter_class =
          case config.notify.to_sym
          when :libnotify
            Signaly::LibnotifyOutputter
          when :growl
            Signaly::GrowlOutputter
          when :notifysend
            Signaly::NotifySendOutputter
          end
        outputter = outputter_class.new(config)
        observables.new_updates.subscribe outputter
        #observables.reminders.subscribe outputter
      end

      while Thread.list.size > 1
        (Thread.list - [Thread.current]).each &:join
      end
    end
  end
end
