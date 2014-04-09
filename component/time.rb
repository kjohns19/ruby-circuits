require_relative 'component'

# Main module for all circuit classes
module Circuits

# Module for components dealing with time
module Time

DelayProperty = Property.create("Delay", Fixnum, :delay, :delay=)

# Component that outputs its input value after a certain amount of time
Delay = Component.create do
   add_property(DelayProperty.new([1,1000,1]))

   attr_accessor :delay

   def initialize(circuit)
      super(1, 1, circuit) do
         @delay = 1
         @values = []
      end
   end

   def update_outputs
      if inputs_current[0] != inputs_old[0]
         delay = @values.empty? ? @delay : @delay-@values[0][1]
         val = inputs_current[0]
         update_next delay if @values.empty?
         @values << [val, delay]
      else
         arr = @values.shift
         return unless arr
         outputs[0] = arr[0]
         update_next @values[0][1] unless @values.empty?
      end
   end
end

# Component that toggles its output after a certain amount of time
Clock = Component.create do
   add_property(DelayProperty.new([1,1000,1]))

   attr_accessor :delay

   def initialize(circuit)
      super(1, 1, circuit) do
         @delay = 1
         outputs[0] = false
      end
   end
   def update_outputs
      if inputs_current[0]
         @last = circuit.remove_update self
      elsif @last
         update_next @last
         @last = nil
      else
         outputs[0] = !outputs[0]
         update_next @delay
      end
   end
end

end

end
