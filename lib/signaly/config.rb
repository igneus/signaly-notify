module Signaly
  Config = Struct.new(
    :sleep_seconds, # between checks
    :remind_after, # the first notification
    :notification_showtime,
    :debug_output,
    :login,
    :password,
    :url, # of the checked page
    :skip_login,
    :config_file,
    :console_only,
    :notify
  )

  class Config
    def self.default
      defaults = new
      # how many seconds between two checks of the site
      defaults.sleep_seconds = 60
      # if there is some pending content and I don't look at it,
      # remind me after X seconds
      defaults.remind_after = 60*5
      # for how long time the notification shows up
      defaults.notification_showtime = 10
      defaults.debug_output = false
      defaults.password = nil
      return defaults
    end

    # merges the config structs so that the last one
    # in the argument list has the highest priority and value nil is considered
    # empty
    def merge(other)
      merged = dup

      merged.members.each do |key|
        merged[key] = other[key] if other[key]
      end

      return merged
    end
  end
end
