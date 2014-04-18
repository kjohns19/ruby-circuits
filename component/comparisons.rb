require_relative 'function'

# Main module for all circuit classes
module Circuits

# Module for comparing inputs
module Comparisons

BoolType = Property.create('True/False', TrueClass, :use_bool, :use_bool=)

# This could take only 2 inputs, but why not make it take more?
# This computes whether all of the inputs are equal
Equal = Component.create do
   variable_inputs(2, 10)
   add_property(BoolType.new(nil))

   attr_accessor :use_bool

   def initialize(circuit, &block)
      super(2, 1, circuit, &block)
      self.use_bool = true
   end
   def update_outputs
      first = inputs_current[0]
      inputs_current.each_with_index do |input, i|
         next if i.zero?
         if (first != input)
            outputs[0] = use_bool ? false : 0
            return
         end
      end
      outputs[0] = use_bool ? true : 1
   end
end

# This could take only 2 inputs, but why not make it take more?
# This computes whether any of the inputs are not equal
NotEqual = Component.create(Equal) do
   def update_outputs
      super
      outputs[0] = use_bool ? !outputs[0] : outputs[0] == 0 ? 1 : 0
   end
end

compare = Component.create do
   add_property(BoolType.new(nil))
   attr_accessor :use_bool
   def initialize(circuit, &block)
      super(2, 1, circuit) do
         self.use_bool = true
         block.call self if block
      end
   end

   def update_outputs
      res = inputs_current[0].send(self.class.func, inputs_current[1])
      outputs[0] = use_bool ? res : res ? 1 : 0
   rescue
      outputs[0] = nil
   end

   def self.func
      @func
   end
   def self.func=(func)
      @func = func
   end
end

Greater        = Component.create(compare) { self.func = :> }
Less           = Component.create(compare) { self.func = :< }
GreaterOrEqual = Component.create(compare) { self.func = :>= }
LessOrEqual    = Component.create(compare) { self.func = :<= }
Between        = Component.create(compare) { self.func = :between? }
Compare        = Function.create(:<=>, 1)

end

end
