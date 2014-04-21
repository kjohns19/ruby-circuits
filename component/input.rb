require_relative 'component'

# Main module for all circuit classes
module Circuits

# Module for input components
module Input

# Component that outputs constant values
Constant = Component.create do
   variable_outputs(1, 10)
   add_property(Property.new("Values", Array, [nil,nil,:output_count], :values, :values=))

   def initialize(circuit, &block)
      super(0, 1, circuit, &block)
   end

   def values=(values)
      values = values[0...output_count]
      # We have to do this so the outputs are sent to connected components
      values.each_with_index do |v, i|
         outputs[i] = v
      end
   end
   def values
      Array.new(outputs)
   end
end

Button = Component.create do
   add_property(Property.new("On Value", nil, nil, :on_value, :on_value=))
   add_property(Property.new("Off Value", nil, nil, :off_value, :off_value=))
   add_property(Property.new("Delay", Fixnum, [0,100,1], :delay, :delay=))
   add_property(Property.new("Active", TrueClass, nil, :on, :on=))

   attr_reader :on_value, :off_value
   attr_accessor :delay

   def initialize(circuit)
      @initial = true
      super(0, 1, circuit) do
         self.delay = 1
         self.on = false
         self.on_value = true
         self.off_value = false
         yield self if block_given?
      end
      @initial = nil
      @done = false
   end

   def on_value=(value)
      @on_value = value
      outputs[0] = value if on
   end
   def off_value=(value)
      @off_value = value
      outputs[0] = value unless on
   end

   attr_reader :on

   def on=(on)
      @on = on
      outputs[0] = on ? on_value : off_value
   end

   def click(button)
      return unless button == 1
      if delay == 0
         unless @done
            self.on = !on
            @done = true
         end
      else
         self.on = true
      end
      if circuit
         circuit.remove_update self
         circuit.update_next self, delay+1
      end
   end

   def update_outputs
      self.on = false if @initial.nil? && !@done
      @done = false
   end
end

end

end
