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

   attr_reader :on_value, :off_value
   attr_accessor :delay

   def initialize(circuit)
      super(0, 1, circuit) do
         self.delay = 1
         yield self if block_given?
      end
   end

   def on_value=(value)
      @on_value = value
      outputs[0] = value if active?
   end
   def off_value=(value)
      @off_value = value
      outputs[0] = value unless active?
   end

   def active?
      @active
   end

   def active=(active)
      @active = active
      outputs[0] = active ? on_value : off_value
   end

   def click(button)
      return unless button == 1
      if delay == 0
         self.active = !active?
      else
         self.active = true
         if circuit
            circuit.remove_update self
            circuit.update_next self, delay
         end
      end
   end

   def update_outputs
      self.active = false
   end
end

end

end
