require_relative 'component'

# Main module for all circuit classes
module Circuits

# Base class for many components
#
# Variables:
#     function - the function to call when inputs change
#     args     - the number of arguments for the function
# Inputs:
#     in1-inN - If the function is a Proc, lambda, or method,
#               in1-inN are used as arguments to the function
#               If the function is a symbol, the function is sent as
#               as a message to the in1 with in2-inN as arguments
# Outputs:
#     value - The value returned by the function or nil if there was an error
class Function < Component

   # Returns a new function class that will uss
   # the specified function when instances' inputs change
   def self.create(function, arg_count, clone=false)
      klass = Class.new(Function)
      klass.function = function
      klass.class_eval %Q(
         def initialize(circuit)
            super(self.class.function, #{arg_count}, circuit, #{clone})
         end
      )
      yield klass if block_given?
      return klass
   end

   attr_reader :function

   def initialize(function, arg_count, circuit, clone=false)
      @call = function.is_a?(Proc) || function.is_a?(Method)
      super(arg_count + (@call ? 0 : 1), 1, circuit) do
         @function = function
         @clone = clone
         yield if block_given?
      end
   end

   def update_outputs
      begin
         if @call
            outputs[0] = @function.call(*inputs_current)
         else
            obj = inputs_current[0]
            obj = obj.dup if @clone
            args = inputs_current.drop(1)
            outputs[0] = obj.send(@function, *args)
         end
      rescue
         outputs[0] = nil
      end
      inputs_current[0] = old if @clone
   end

   protected
   def self.function
      @function
   end

   private
   def self.function=(function)
      @function = function
   end
end

# Base class for many components
#
# Variables:
#     function - the binary function to call when inputs change
#     inputs   - the number of inputs
# Inputs:
#     in1-inN - If the function is a Proc, lambda, or method,
#               the function is applied like this:
#                 f(f(...(f(in1, in2), in3)...),inN)
#               If the function is a symbol,
#               the function is applied like this:
#                 in1.f(in2).f(in3)...f(inN)
# Outputs:
#     value - The value returned by the binary function
#             applied to the inputs or nil if there was an error
class BinaryOperator < Component

   variable_inputs(2, 10)

   # Returns a new binary operator class that will uss
   # the specified function when instances' inputs change
   def self.create(function, clone=false)
      klass = Class.new(BinaryOperator)
      klass.function = function
      klass.class_eval %Q(
         def initialize(circuit)
            super(self.class.function, circuit, #{clone})
         end
      )
      yield klass if block_given?
      return klass
   end

   attr_reader :function

   def initialize(function, circuit, clone=false)
      super(2, 1, circuit) do
         @function = function
         @clone = clone
         @block = @function.is_a?(Proc) || @function.is_a?(Method)
         yield if block_given?
      end
   end

   # Called whenever an input changes
   def update_outputs
      if @clone
         old = inputs_current[0]
         inputs_current[0] = old.dup if old
      end
      begin
         if @block
            outputs[0] = inputs_current.reduce(&@function)
         else
            outputs[0] = inputs_current.reduce(@function)
         end
      rescue
         outputs[0] = nil
      end
      inputs_current[0] = old if @clone
   end

   protected
   def self.function
      @function
   end

   private
   def self.function=(function)
      @function = function
   end
end

end
