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

end

end
