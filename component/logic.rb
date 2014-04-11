require_relative 'function'

# Main module for all circuit classes
module Circuits

# Module for boolean logic components
module Logic

And = Component.create do
   variable_inputs(2, 10)
   def initialize(circuit, &block)
      super(2, 1, circuit, &block)
   end

   def update_outputs
      inputs_current.each do |i|
         if !i or i == 0
            outputs[0] = false
            return
         end
      end
      outputs[0] = true
   end
end

Or = Component.create do
   variable_inputs(2, 10)
   def initialize(circuit, &block)
      super(2, 1, circuit, &block)
   end

   def update_outputs
      inputs_current.each do |i|
         unless !i or i == 0
            outputs[0] = true
            return
         end
      end
      outputs[0] = false
   end
end

XOr = Component.create do
   variable_inputs(2, 10)
   def initialize(circuit, &block)
      super(2, 1, circuit, &block)
   end
   def update_outputs
      ins = inputs_current
      result = (!ins[0] || ins[0] == 0) ? false : true
      ins.each_with_index do |input, i|
         next if i == 0
         val = (!ins[0] || ins[0] == 0) ? false : true
         result = result ^ val
      end
      outputs[0] = result
   end
end

Nand = Component.create(And) do
   def update_outputs
      super
      outputs[0] = !outputs[0]
   end
end

Nor = Component.create(Or) do
   def update_outputs
      super
      outputs[0] = !outputs[0]
   end
end

XNor = Component.create(XOr) do
   def update_outputs
      super
      outputs[0] = !outputs[0]
   end
end

Not = Function.create(:!, 0)

Mux = Component.create do
   variable_inputs(3, 10)
   def initialize(circuit, &block)
      super(3, 1, circuit, &block)
   end

   def input_label(input)
      case input
      when 0
         "Select"
      else
         super(input-1)
      end
   end

   def update_outputs
      select = inputs_current[0]
      begin
         if input_count == 2
            outputs[0] = inputs_current[1][select]
         else
            outputs[0] = inputs_current[select+1]
         end
      rescue
         outputs[0] = nil
      end
   end
end

DeMux = Component.create do
   variable_outputs(2, 10)
   def initialize(circuit, &block)
      super(2, 2, circuit, &block)
   end

   def input_label(input)
      case input
      when 0
         "Select"
      else
         "In"
      end
   end

   def update_outputs
      select = inputs_current[0]
      last = inputs_old[0]
      begin
         outputs[last] = nil if last && select != last
         outputs[select] = inputs_current[1]
      rescue

      end
   end
end

end

end
