require_relative 'component'

# Main module for all circuit classes
module Circuits


FunctionProperty = Property.create("Function", String, :function, :function=)
ArgumentCountProperty = Property.create("Arguments", Fixnum, :arg_count, :arg_count=)
CloneProperty = Property.create("Clone", TrueClass, :use_clone, :use_clone=)

# Base class for many components
class Function < Component
   variable_inputs(1, 10, false)
   add_property FunctionProperty.new(nil, false)
   add_property ArgumentCountProperty.new([1,10,1], false)
   add_property CloneProperty.new(nil, false)

   # Returns a new function class that will uss
   # the specified function when instances' inputs change
   def self.create(function, arg_count, clone=false)
      klass = Component.create(Function)
      klass.function = function
      klass.class_eval %Q(
         def initialize(circuit)
            super(circuit) do
               self.function = self.class.function
               self.arg_count = #{arg_count}
               self.use_clone = #{clone}
            end
         end
      )
      yield klass if block_given?
      return klass
   end

   def function=(function)
      function = function.to_sym if function.is_a? String
      @call = function.is_a?(Proc) || function.is_a?(Method)
      input_count = @arg_count + (@call ? 0 : 1) if @arg_count
      @function = function
   end

   attr_reader :function

   def arg_count
      @arg_count
   end
   def arg_count=(count)
      @arg_count = count
      input_count = @arg_count + (@call ? 0 : 1)
   end

   def use_clone
      @clone
   end
   def use_clone=(clone)
      @clone = clone
   end

   def initialize(circuit)
      super(1, 1, circuit) do
         self.function = :+
         self.arg_count = 1
         self.use_clone = false
         yield if block_given?
      end
   end

   def update_outputs
      if (@function.nil?)
         outputs[0] = nil
         return
      end
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
class BinaryOperator < Component
   add_property FunctionProperty.new(nil, false)
   variable_inputs(2, 10)
   add_property CloneProperty.new(nil, false)

   # Returns a new binary operator class that will uss
   # the specified function when instances' inputs change
   def self.create(function, clone=false)
      klass = Component.create(BinaryOperator)
      klass.function = function
      klass.class_eval %Q(
         def initialize(circuit)
            super(circuit) do
               self.function = self.class.function
               self.use_clone = #{clone}
            end
         end
      )
      yield klass if block_given?
      return klass
   end

   attr_reader :function

   def function=(function)
      function = function.to_sym if function.is_a? String
      @function = function
      @block = @function.is_a?(Proc) || @function.is_a?(Method)
   end

   def use_clone
      @clone
   end
   def use_clone=(clone)
      @clone = clone
   end

   def initialize(circuit)
      super(2, 1, circuit) do
         self.function = :+
         self.use_clone = false
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
