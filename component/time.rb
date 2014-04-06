require_relative 'component'

# Main module for all circuit classes
module Circuits

# Module for components dealing with time
module Time

# Component that outputs its input value after a certain amount of time
# Variables:
#     delay - The number of cycles to wait before setting output
# Inputs:
#     value - The output will be set to this value after 'delay' cycles
# Outputs:
#     value - The delayed output
class Delay < Component
   def initialize(delay, circuit)
      super(1, 1, circuit) do
         @delay = delay
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
# Variables:
#     delay - How often to toggle output. 1 means toggle every cycle
# Inputs:
#     pause - When true, pauses the clock from toggling
#             When changed to false, the clock resumes where it left off
# Outputs:
#     value - Either true or false. Is toggled every 'delay' cycles
class Clock < Component
   attr_accessor :delay
   def initialize(delay, circuit)
      super(1, 1, circuit) do
         @delay = delay
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
