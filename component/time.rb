require_relative 'component'

# Main module for all circuit classes
module Circuits

# Module for components dealing with time
module Time

DelayProperty = Property.create("Delay", Fixnum, :delay, :delay=)

# Component that outputs its input value after a certain amount of time
Delay = Component.create do
   add_property(Property.new("Delay", Fixnum, [1,1000,1], :delay, :delay=))

   attr_accessor :delay

   def initialize(circuit)
      super(1, 1, circuit) do
         @delay = 1
         @values = []
         yield self if block_given?
      end
   end

   def update_outputs
      return if circuit.nil?
      time = circuit.time
      if inputs_current[0] != inputs_old[0]
         val = inputs_current[0]
         @values << [val, time+@delay]
         if @values.length == 1
            update_next @delay
         end
      end
      return if @values.empty?
      if @values[0][1] <= time
         arr = @values.shift
         return unless arr
         outputs[0] = arr[0]
         unless @values.empty?
            update_next(@values[0][1]-time)
         end
      end
   end
end

# Component that toggles its output after a certain amount of time
Clock = Component.create do
   add_property(Property.new("On Time", Fixnum, [1,1000,1], :on_time, :on_time=))
   add_property(Property.new("Off Time", Fixnum, [1,1000,1], :off_time, :off_time=))

   attr_reader :on_time, :off_time

   def on_time=(time)
      return if time == @on_time
      @on_time = time
      return unless outputs[0]
      circuit.remove_update self if circuit
      if @last
         @last = @on_time
      else
         update_next @on_time
      end
   end
   def off_time=(time)
      return if time == @off_time
      @off_time = time
      return if outputs[0]
      circuit.remove_update self if circuit
      if @last
         @last = @off_time
      else
         update_next @off_time
      end
   end

   def initialize(circuit)
      super(1, 1, circuit) do
         @on_time = 1
         @off_time = 1
         outputs[0] = false
         yield self if block_given?
      end
   end

   def input_label(input)
      "stop"
   end

   def update_outputs
      if inputs_current[0]
         @last = circuit.remove_update self
      elsif @last
         update_next @last
         @last = nil
      else
         outputs[0] = !outputs[0]
         if outputs[0]
            update_next @on_time
         else
            update_next @off_time
         end
      end
   end
end

end

end
