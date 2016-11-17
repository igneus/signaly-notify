# optional gems for visual notifications
begin
  require 'libnotify'
rescue LoadError
end

module Signaly
  class LibnotifyOutputter < StatusOutputter
    def output(new_status, old_status)
      p [new_status, old_status]
      text = [:pm, :notifications, :invitations].collect do |what|
        "#{what}: #{new_status[what]}"
      end.join "\n"

      Libnotify.show(:body => text, :summary => "signaly.cz", :timeout => @config.notification_showtime)
    end
  end
end
