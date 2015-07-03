module MultiProperty
  def self.generate_id
    # Start with the low-order 43 bits of the time in milliseconds...
    # The time in ms currently takes up 41 bits.  It will take
    # a couple of centuries for the 43-bit value to wrap around.
    timestamp = Time.now
    msec = timestamp.to_i * 1000 + timestamp.usec / 1000
    msec = msec & ((1 << 43) - 1)

    # Then append 20 bits of randomness, and use the result as
    # the unique 64-bit ID.  The high order bit is unused, to
    # avoid negative ID values.
    return (msec << 20) + rand(1 << 20)
  end
  
  module RandomPrimaryKeyHelper
    def self.included(base)
      base.class_eval do
        before_create :set_id
        def set_id
          self.id = MultiProperty.generate_id if self.id.blank?
        end
      end
    end
  end
  
end