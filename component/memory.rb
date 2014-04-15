require_relative 'component'

# Main module for all circuit classes
module Circuits

# Module for memory components
module Memory

ValueProperty = Property.create("Value", nil, :value, :value=)

DLatch = Component.create do
   add_property ValueProperty.new(nil)

   def initialize(circuit, &block)
      super(2, 1, circuit, &block)
   end

   def input_label(input)
      input == 0 ? "clk" : "data"
   end

   def update_outputs
      outputs[0] = inputs_current[1] if inputs_current[0]
   end

   def value
      outputs[0]
   end
   def value=(value)
      outputs[0] = value
   end
end

DFlipFlop = Component.create do
   add_property ValueProperty.new(nil)

   def initialize(circuit, &block)
      super(2, 1, circuit, &block)
   end

   def input_label(input)
      input == 0 ? "clk" : "data"
   end

   def update_outputs
      outputs[0] = inputs_current[1] if inputs_current[0] && !inputs_old[0]
   end

   def value
      outputs[0]
   end
   def value=(value)
      outputs[0] = value
   end
end

end

end
