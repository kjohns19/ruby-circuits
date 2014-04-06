require 'set'

require_relative '../property'

# Add function to resize an array easily
class Array
   def resize(size, value=nil)
      return self if size == length

      if size < length
         slice!(size, length-size)
      else
         a = Array.new(size-length, value)
         concat(a)
      end
   end
end

module Circuits

Wire = Struct.new(:input, :output, :comp_in, :comp_out)

VarInputsProperty = Property.create("# of inputs", Fixnum,
                                    :input_count, :input_count=)
VarOutputsProperty = Property.create("# of outputs", Fixnum,
                                     :output_count, :output_count=)

class Component

   attr_reader :input_count, :output_count
   attr_reader :inputs_current, :inputs_old
   attr_reader :outputs
   attr_reader :in_connections, :out_connections
   attr_reader :circuit

   def initialize(inputs, outputs, circuit)
      raise ArgumentError, "# of inputs must be between 0 and 10" unless
         inputs.between?(0, 10)
      raise ArgumentError, "# of outputs must be between 0 and 10" unless
         outputs.between?(0, 10)
      @outputs = Outputs.new(outputs, self);
      @input_count = inputs
      @output_count = outputs

      @inputs_current = Array.new(inputs)
      @inputs_next = NewInputs.new(inputs, self)
      @inputs_old = Array.new(inputs)

      @in_connections = Array.new(inputs)
      @out_connections = Array.new(outputs)
      @out_connections.map! {|x| Set.new }

      @circuit = circuit
      circuit.add self if circuit

      yield if block_given?
      update_outputs
   end

   def circuit=(circuit)
      if @circuit
         @circuit.remove_all_updates self
         @circuit.remove self
      end
      @circuit = circuit
      circuit.add self if circuit
   end

   def update_inputs
      @inputs_current, @inputs_old = @inputs_old, @inputs_current
      @inputs_current.replace(@inputs_next)
      return nil
   end

   def update_outputs
   end

   def update_next(delay=1)
      @circuit.update_next(self, delay) if @circuit
   end
   def stop_update
      @circuit.remove_update(self) if @circuit
   end

   def connect_input(input, component, output)
      return unless input.between?(0, input_count-1) && output.between?(0, component.output_count-1)
      disconnect_input(input)
      conn = Wire.new(input, output, self, component)
      in_connections[input] = conn
      component.out_connections[output] << conn
      inputs_next[input] = component.outputs[output]
   end

   def disconnect_input(input)
      return unless input.between?(0, input_count-1)
      conn = in_connections[input]
      return unless conn
      conn.comp_out.out_connections[conn.output].delete(conn)
      inputs_next[input] = nil
   end

   def disconnect_outputs(output)
      return unless output.between?(0, output_count-1)
      conns = out_connections[output]
      out_connections[output] = Set.new
      conns.each do |conn|
         conn.comp_in.disconnect_input(conn.input)
      end
   end

   def delete
      if @circuit
         @circuit.remove_all_updates self
         @circuit.remove self
         @circuit = nil
      end
      inputs.new.length.each do |i|
         disconnect_input(i)
      end
   end

   def self.variable_inputs(min, max)
      add_property(VarInputsProperty.new(min..max))
      class_eval %Q(
         def input_count=(count)
            return if count == input_count
            return unless count.between?(#{min}, #{max})
            if count < input_count
               (count...input_count).each { |i| disconnect_input(i) }
            end
            inputs_next.resize(count)
            inputs_current.resize(count)
            inputs_old.resize(count)
            @input_count = count
            update_next
         end)
   end
   def self.variable_outputs(min, max)
      add_property(VarOutputsProperty.new(min..max))
      class_eval %Q(
         def output_count=(count)
            return if count == output_count
            return unless count.between?(#{min}, #{max})
            if count < output_count
               (count...output_count).each { |i| disconnect_outputs(i) }
            end
            outputs.resize(count)
            @output_count = count
         end)
   end

   def self.add_property(property)
      @properties = properties
      @properties << property
   end

   def self.properties
      if @properties.nil?
         if self == Component
            @properties = []
         else
            puts "I am #{self.name}, super is #{self.superclass}"
            @properties = Array.new(self.superclass.properties)
         end
      end
      return @properties
   end

   def self.creation_time=(time)
      @creation_time = time
      puts "Hey! Creation time of #{time}"
   end

   def self.creation_time
      @creation_time||=0
   end

private
   attr_reader :inputs_next

   class Outputs < Array
      def initialize(count, component)
         super(count)
         @comp = component
      end
      def []=(i, value)
         return nil unless i.between?(0, length-1)
         super(i,value)
         conns = @comp.out_connections[i]
         conns.each do |conn|
            conn.comp_in.inputs_next[conn.input] = value
         end
         return value
      end
   end

   class NewInputs < Array
      def initialize(count, component)
         super(count)
         @comp = component
      end

      def []=(i, value)
         return nil unless i.between?(0, length-1)
         current = @comp.inputs_current[i]
         oldVal = self[i]
         super(i, value)
         value.freeze
         if current != value
            @comp.update_next
         elsif oldVal != value
            @comp.stop_update if self == @comp.inputs_current
         end
         return value
      end
   end
end

end
