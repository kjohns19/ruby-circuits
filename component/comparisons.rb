require_relative 'function'

# Main module for all circuit classes
module Circuits

# Module for comparing inputs
module Comparisons

# This could take only 2 inputs, but why not make it take more?
# This computes whether all of the inputs are equal
class Equal < Component
   variable_inputs(2, 10)
   def initialize(circuit)
      super(2, 1, circuit)
   end
   def update_outputs
      first = inputs_current[0]
      inputs_current.each_with_index do |input, i|
         next if i.zero?
         if (first != input)
            outputs[0] = false
            return
         end
      end
      outputs[0] = true
   end
end

# This could take only 2 inputs, but why not make it take more?
# This computes whether any of the inputs are not equal
class NotEqual < Equal
   def update_outputs
      super
      outputs[0] = !outputs[0]
   end
end

# Other comparisons (self-explanatory)
Greater        = Function.create(:>,   1)
Less           = Function.create(:<,   1)
GreaterOrEqual = Function.create(:>=,  1)
LessOrEqual    = Function.create(:<=,  1)
Compare        = Function.create(:<=>, 1)
Between        = Function.create(:between?, 2)

end

end
