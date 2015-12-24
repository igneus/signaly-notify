module Signaly
  # how many PMs, notifications, invitations a user has at a time
  class Status < Struct.new(:pm, :notifications, :invitations)

    def initialize(pm=0, notifications=0, invitations=0)
      super(pm, notifications, invitations)
    end

    def is_there_anything?
      self.each_pair {|k,v| return true if v > 0 }
      return false
    end

    # does self have anything new compared with other?
    def >(other)
      if other.nil?
        return true
      end

      [:pm, :notifications, :invitations].each do |prop|
        if send(prop) > other.send(prop) then
          return true
        end
      end

      return false
    end

    # is there any change between old_status and self in property prop?
    def changed?(old_status, prop)
      (old_status == nil && self[prop] > 0) ||
        (old_status != nil && self[prop] != old_status[prop])
    end
  end
end
