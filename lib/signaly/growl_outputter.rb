begin
  require 'ruby-growl'
rescue LoadError
end

module Signaly
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
