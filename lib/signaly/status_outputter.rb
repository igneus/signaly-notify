module Signaly
  class StatusOutputter
    def initialize(config)
      @config = config
    end

    def output(new_status, old_status)
    end
  end

  class ConsoleOutputter < StatusOutputter
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

  class LibNotifyOutputter < StatusOutputter
    def output(new_status, old_status)
      text = [:pm, :notifications, :invitations].collect do |what|
        "#{what}: #{new_status[what]}"
      end.join "\n"

      Libnotify.show(:body => text, :summary => "signaly.cz", :timeout => @config.notification_showtime)
    end
  end

  class GrowlOutputter < StatusOutputter
    def output(new_status, old_status)
      text = [:pm, :notifications, :invitations].collect do |what|
        "#{what}: #{new_status[what]}"
      end.join "\n"

      notif = Growl.new 'localhost', 'ruby-growl', 'GNTP'
      notif.notify('signaly.cz', 'signaly.cz', text)
    end
  end
end
