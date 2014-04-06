require_relative 'component'

# Main module for all circuit classes
module Circuits

# Module for utility components
module Util

# Component to convert inputs to an array
# Variables:
#     inputs - The number of inputs (1-10 inclusive)
# Inputs:
#     in1-inN - The inputs (may be any values)
# Outputs:
#     array - The inputs as an array -- [in1, in2, ..., inN]
class ToArray < Component
   variable_inputs(1, 10)
   def initialize(inputs, circuit)
      super(inputs, 1, circuit)
   end

   def update_outputs
      outputs[0] = inputs_current.clone
   end
end

end

end
