require 'colorized_string'

module Signaly
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
          num = ColorizedString.new(num).red
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
end
