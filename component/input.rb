require_relative 'component'

# Main module for all circuit classes
module Circuits

# Module for input components
module Input

# Component that outputs constant values
Constant = Component.create do
   variable_outputs(1, 10)
   add_property(Property.new("Values", Array, [[nil,nil]]*10, :values, :values=))

   def initialize(circuit)
      super(0, 1, circuit)
   end

   def values=(values)
      puts "Hey! #{values.inspect} -> #{output_count}"
      values = values[0...output_count]
      outputs.replace(values)
   end
   def values
      Array.new(outputs)
   end
end

end

end
