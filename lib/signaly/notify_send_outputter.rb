module Signaly
  # sends desktop notification using the command-line utility
  # notify-send (useful for those who have installed libnotify,
  # but not the Ruby bindings)
  class NotifySendOutputter < StatusOutputter
    def output(new_status, old_status)
      text = [:pm, :notifications, :invitations].collect do |what|
        "#{what}: #{new_status[what]}"
      end.join "\n"

      `notify-send "#{text}"`
    end
  end
end
