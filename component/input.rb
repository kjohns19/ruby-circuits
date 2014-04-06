require_relative 'component'

# Main module for all circuit classes
module Circuits

# Module for input components
module Input

# Component that outputs constant values
class Constant < Component
   variable_outputs(1, 10)
   def initialize(values, circuit)
      super(0, values.length, circuit)
      outputs.replace(values)
   end
end

end

end
