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

FromArray = Component.create do
   variable_outputs(1, 10)

   def initialize(circuit, &block)
      super(1, 1, circuit, &block)
   end

   def update_outputs
      arr = inputs_current[0]
      arr[0..output_count-1].each_with_index do |value, i|
         outputs[i] = value
      end
      (arr.length..output_count-1).each do |i|
         outputs[i] = nil
      end
   rescue
      output_count.times do |i|
         outputs[i] = nil
      end
   end
end

end

end
