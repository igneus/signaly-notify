module Signaly
  class StatusOutputter
    def initialize(config)
      @config = config
    end

    def output(new_status, old_status)
    end

    # Rx observer interface:

    def on_next(statuses)
      old_status, new_status = statuses
      output new_status, old_status
    end

    def on_error(error)
      STDERR.puts error # TODO
    end

    def on_completed
    end
  end
end
