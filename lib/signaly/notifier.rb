module Signaly
  # dispatches events to observers - subscribed notifiers
  class Notifier
    def initialize
      @outputters = {}
    end

    def add_outputter(outputter, *events)
      events.each do |event|
        @outputters[event] ||= []
        @outputters[event] << outputter
      end
      self
    end

    def emit(event, *args)
      if @outputters[event]
        @outputters[event].each {|o| o.output *args }
      end
      self
    end
  end
end
