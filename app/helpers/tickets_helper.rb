module TicketsHelper
  
  def pretty_duration(s)
    s = s.to_i
    tm = s / 1.minutes
    s2 = s - tm.minutes.seconds

    tm > 0 ? (s2 == 0 ? "#{tm}m" : "#{tm}m:#{s2}s") : "#{s}s"
  end
  
end
