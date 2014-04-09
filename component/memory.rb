require_relative 'component'

# Main module for all circuit classes
module Circuits

# Module for memory components
module Memory

ValueProperty = Property.create("Value", nil, :value, :value=)

DLatch = Component.create do
   add_property ValueProperty.new(nil)

   def initialize(circuit)
      super(2, 1, circuit)
   end

   def update_outputs
      outputs[0] = inputs_current[0] if inputs_current[1]
   end

   def value
      outputs[0]
   end
end

DFlipFlop = Component.create do
   add_property ValueProperty.new(nil)

   def initialize(circuit)
      super(2, 1, circuit)
   end

   def update_outputs
      outputs[0] = inputs_current[0] if inputs_current[1] && !inputs_old[1]
   end

   def value
      outputs[0]
   end
end

end

end
