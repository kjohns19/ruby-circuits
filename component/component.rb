require 'set'

require_relative '../property'
require_relative '../display/component_display'

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

class Component
include Circuits::Display::ComponentDisplay
   # Used to keep track of component creation order
   @@creation_time = 0


   # Creates a new component type. Evaluates the block given using class_eval.
   # This is the preferred way of creating new component types.
   def self.create(base = Component, &block)
      raise ArgumentError,
            "Base class not a type of Component" unless base <= Component

      klass = Class.new(base)
      klass.creation_time = @@creation_time
      klass.class_eval &block if block

      @@creation_time += 1

      return klass
   end

   attr_reader :input_count, :output_count
   attr_reader :inputs_next, :inputs_current, :inputs_old
   attr_reader :outputs
   attr_reader :in_connections, :out_connections
   attr_reader :circuit
   attr_accessor :position
   attr_accessor :label
   attr_accessor :id
   attr_writer :active

   def self.label
      self.name.split('::').last
   end

   # Default label for input ports
   # If there are multiple inputs, the label will be 'in#' (# is the input port)
   # If there is 1 input the label will just be 'in'
   def input_label(input)
      input_count == 1 ? "in" : "in#{input+1}"
   end
   # Default label for output ports
   # If there are multiple outputs, the label will be 'out#' (# is the output port)
   # If there is 1 output the label will just be 'out'
   def output_label(output)
      output_count == 1 ? "out" : "out#{output+1}"
   end

   # Initializes a new component and then calls update_outputs.
   # If a block is given it will be called with self as an argument.
   # The block is called before running update_outputs
   def initialize(inputs, outputs, circuit)
      # Check for valid inputs and outputs
      raise ArgumentError, "# of inputs must be between 0 and 10" unless
         inputs.between?(0, 10)
      raise ArgumentError, "# of outputs must be between 0 and 10" unless
         outputs.between?(0, 10)
      @input_count = inputs
      @output_count = outputs

      # Output values
      @outputs = Outputs.new(outputs, self);

      # Input values - current, next, and old
      @inputs_current = Array.new(inputs)
      @inputs_next = NewInputs.new(inputs, self)
      @inputs_old = Array.new(inputs)

      # Connections
      @in_connections = Array.new(inputs)
      @out_connections = Array.new(outputs)
      @out_connections.map! {|x| Set.new }

      # Id (used to find the component in a circuit)
      @id = -1

      @circuit = circuit
      circuit.add_component self if circuit

      @position = [0,0]

      @active = true

      self.label = self.class.label
      self.invert = false

      yield self if block_given?
      update_outputs if @active
   end

   # Changes the circuit the component is in
   def circuit=(circuit)
      if @circuit
         @circuit.remove_all_updates self
         @circuit.remove_component self
      end
      @circuit = circuit
      circuit.add_component self if circuit
   end

   # This is called first when the component is updated
   def update_inputs
      @inputs_current, @inputs_old = @inputs_old, @inputs_current
      @inputs_current.replace(@inputs_next)
      return nil
   end

   # This is called when the component is updated (after inputs are updated)
   def update_outputs
   end

   # If the component is active, this causes the component to be updated
   # in the given number of cycles (default is 1, which is the next cycle)
   def update_next(delay=1)
      @circuit.update_next(self, delay) if @circuit && self.active?
   end
   def stop_update
      @circuit.remove_update(self) if @circuit
   end

   # Connects a wire to an input port
   def connect_input(conn)
      input, output, component = conn.input, conn.output, conn.comp_out
      return unless input.between?(0, input_count-1) && output.between?(0, component.output_count-1)
      disconnect_input(input)
      in_connections[input] = conn
      component.out_connections[output] << conn
      inputs_next[input] = component.outputs[output]
   end

   # Disconnects a connection to an input port if it exists
   def disconnect_input(input)
      return unless input.between?(0, input_count-1)
      conn = in_connections[input]
      return unless conn
      conn.comp_out.out_connections[conn.output].delete(conn)
      inputs_next[input] = nil
      in_connections[input] = nil
      conn.delete
   end

   # Disconnects all connections to an output port
   def disconnect_outputs(output)
      return unless output.between?(0, output_count-1)
      conns = out_connections[output]
      out_connections[output] = Set.new
      conns.each do |conn|
         conn.comp_in.disconnect_input(conn.input)
      end
   end

   # These are called when the user clicks (and releases) the mouse on the component
   def click(button)
   end
   def release(button)
   end

   def translate(amount)
      self.position = [self.position[0]+amount[0], self.position[1]+amount[1]]
   end

   # Deletes the component, removing itself and its connections from the circuit
   def delete
      if @circuit
         @circuit.remove_all_updates self
         @circuit.remove_component self
      end
      input_count.times do |i|
         disconnect_input(i)
      end
      output_count.times do |i|
         disconnect_outputs(i)
      end
      @circuit = nil
   end

   # Returns whether the component is active
   # An inactive component will not be updated due to changes in inputs
   def active?
      @active
   end

   # Allows the component to have a variable number of inputs
   # The third argument determines whether it should be a property or not
   def self.variable_inputs(min, max, property = true)
      add_property(Property.new("Inputs", Fixnum, [min, max, 1],
                   :input_count, :input_count=)) if property
      class_eval %Q(
         def input_count=(count)
            return if count == input_count
            return unless count.is_a?(Integer) && count.between?(#{min}, #{max})
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
   
   # Allows the component to have a variable number of outputs
   # The third argument determines whether it should be a property or not
   def self.variable_outputs(min, max, property = true)
      add_property(Property.new("Outputs", Fixnum, [min, max, 1],
                   :output_count, :output_count=)) if property
      class_eval %Q(
         def output_count=(count)
            return if count == output_count
            return unless count.is_a?(Integer) && count.between?(#{min}, #{max})
            if count < output_count
               (count...output_count).each { |i| disconnect_outputs(i) }
               @out_connections.resize(count)
            else
               arr = Array.new(count-output_count)
               arr.map! { |x| Set.new }
               @out_connections.concat(arr)
            end
            outputs.resize(count)
            @output_count = count
         end)
   end

   # Adds a property to the component class
   def self.add_property(property)
      @properties ||= []
      @properties << property
   end

   # Returns a list of the properties in the component class
   def self.properties
      @properties ||= []
      return @properties.clone if self == Component
      props = []
      self.superclass.properties.each do |property|
         props << property if property.inherit?
      end
      return @properties + props
   end

   # Creation time is used to order components in the editor
   def self.creation_time=(time)
      @creation_time = time
   end

   def self.creation_time
      @creation_time
   end

   add_property(Property.new("Label", String, nil, :label, :label=))
   add_property(Property.new("Flip", TrueClass, nil, :invert, :invert=))

private

   # Special class for outputs
   # When a value is changed it sends it to connected components
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

   # Special class for new inputs
   # When a value is changed it freezes the result (to prevent modification)
   # And requests that the component be updated in the next update cycle
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
