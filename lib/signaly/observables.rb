require 'rx'

module Signaly
  # Exposes a few interesting Rx::Observables for observing
  # a user's notifications on signaly.cz
  class Observables
    def initialize(client, config)
      @client = client
      @config = config
    end

    def all_states
      @all_states ||=
        begin
          first = Rx::Observable.just(@client.null_status)
          updates =
            Rx::Observable
            .interval(@config.sleep_seconds)
            .time_interval
            .start_with(0) # don't wait for the first entry
            .map { @client.user_status }

          Rx::Observable
            .concat(first, updates)
            .buffer_with_count(2, 1)
        end
    end

    def new_updates
      # fake
      @state_changes ||=
        all_states
    end

    def reminders
    end
  end
end
