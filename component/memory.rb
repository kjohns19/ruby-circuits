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
   add_property(ValueProperty.new(nil))
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

RAM = Component.create do
   variable_inputs(2, 6, false)
   variable_outputs(1, 2, false)
   add_property(Property.new("# of values", Fixnum, [1, 1000, 1], :value_count, :value_count=))
   add_property(Property.new("Values", Array, [nil,nil,:value_count], :values, :values=))
   add_property(Property.new("Read Ports", Fixnum, [1, 2, 1], :read_ports, :read_ports=))
   add_property(Property.new("Write Ports", Fixnum, [0, 1, 1], :write_ports, :write_ports=))

   def initialize(circuit)
      super(5, 1, circuit) do
         self.value_count = 1
         self.values = [nil]

         @read_ports = 1
         @write_ports = 1
         yield self if block_given?
      end
   end

   attr_accessor :value_count
   attr_reader :values, :read_ports, :write_ports

   def input_label(input)
      return 'clk' if input.zero?
      return "ra#{read_ports > 1 ? input : ""}" if input <= read_ports
      input-=1+read_ports
      write = write_ports > 1 ? input/3+1 : ""
      case input % 3
      when 0
         "we#{write}"
      when 1
         "wa#{write}"
      when 2
         "wd#{write}"
      end
   end
   
   def values=(values)
      @values = values[0...value_count]
   end

   def read_ports=(ports)
      @read_ports = ports
      set_input_output_count
   end
   def write_ports=(ports)
      @write_ports = ports
      set_input_output_count
   end

   def update_outputs
      return unless inputs_current[0] && !inputs_old[0]

      # Read
      read_ports.times do |i|
         addr = inputs_current[i+1]
         next unless addr.is_a? Integer
         outputs[i] = values[addr]
      end

      # Write
      write_ports.times do |i|
         offset = i*3+1+read_ports
         next unless inputs_current[offset]
         addr = inputs_current[offset+1]
         next unless addr.is_a?(Integer) && addr.between?(0, values.length-1)
         values[addr] = inputs_current[offset+2]
      end
   end
private
   def set_input_output_count
      self.input_count = 1+read_ports+write_ports*3
      self.output_count = read_ports
   end
end

end

end
