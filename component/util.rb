require_relative 'component'

# Main module for all circuit classes
module Circuits

# Module for utility components
module Util

# Component to convert inputs to an array
ToArray = Component.create do
   variable_inputs(1, 10)
   def initialize(circuit, &block)
      super(1, 1, circuit, &block)
   end

   def update_outputs
      outputs[0] = inputs_current.clone
   end
end

end

end
