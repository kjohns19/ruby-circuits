require_relative 'component'

# Main module for all circuit classes
module Circuits

# Module for memory components
module Memory

ValueProperty = Property.create("Value", nil, :value, :value=)

DLatch = Component.create do
   add_property ValueProperty.new(nil)

   def initialize(circuit, &block)
      super(2, 1, circuit, &block)
   end

   def input_label(input)
      input == 0 ? "clk" : "data"
   end

   def update_outputs
      outputs[0] = inputs_current[1] if inputs_current[0]
   end

   def value
      outputs[0]
   end
   def value=(value)
      outputs[0] = value
   end
end

DFlipFlop = Component.create do
   variable_inputs(2, 3, false)
   add_property ValueProperty.new(nil)
   add_property(Property.new("WE input", TrueClass, nil, :has_w, :has_w=))

   attr_reader :has_w

   def has_w=(has)
      @has_w = has
      self.input_count = 2 + (has ? 1 : 0)
   end

   def initialize(circuit, &block)
      super(2, 1, circuit, &block)
   end

   def input_label(input)
      case input
      when 0
         'clk'
      when 1
         has_w ? 'write' : 'data'
      when 2
         'data'
      end
   end

   def update_outputs
      data = inputs_current[has_w ? 2 : 1]
      we = !has_w || inputs_current[1]
      outputs[0] = data if inputs_current[0] && !inputs_old[0] && we
   end

   def value
      outputs[0]
   end
   def value=(value)
      outputs[0] = value
   end
end

end

end
