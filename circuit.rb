# Main module for all circuit classes
module Circuits

# Container for components
# Circuits keeps track of which components need inputs/outputs updated
# based on the previous update.
class Circuit
   attr_reader :components
   attr_reader :wires
   attr_writer :changed
   
   def changed?
      @changed
   end

   # Initializes a new circuit
   def initialize
      @components = []
      @wires = []
      @update_map = {}
      @changed = false
   end

   def updates
      @update_map
   end

   # Imports components and wires from the given circuit into this one
   # The other circuit will be cleared
   def import(circuit)
      puts "Merging: #{circuit.components.length} components. #{circuit.wires.length} wires"

      #circuit.components.each { |c| self.add_component c }
      circuit.wires.each { |w| self.add_wire w }

      circuit.updates.each do |delay, set|
         myset = @update_map[delay]
         if myset.nil?
            @update_map[delay] = set
         else
            myset.merge(set)
         end
      end
      circuit.updates.clear


      # Set each component's circuit to self
      # This must be done after getting updates
      circuit.components.clone.each do |c|
         puts "No! #{c}"
         c.circuit = self
      end

      circuit.components.clear
      circuit.wires.clear
      circuit.changed = true

      self.components.each { |c| puts c }
   end

   # Updates the inputs and outputs of all components that requested an update
   def update
      temp_map = {}
      @update_map.each { |k, v| temp_map[k-1] = v }
      @update_map = temp_map

      update_set = @update_map.delete(0)
      return unless update_set

      update_set.each do |component|
         component.update_inputs
      end

      yield if block_given?

      update_set.each do |component|
         component.update_outputs
      end

      self.changed = true
   end

   # Adds a component to be updated after the given amount of time
   # by default the component will update in the next cycle (when delay == 1)
   def update_next(component, delay=1)
      delay = 1 unless delay.is_a?(Fixnum) && delay > 0

      update_set = @update_map[delay]
      unless update_set
         update_set = Set.new
         @update_map[delay] = update_set
      end
      update_set << component
   end

   # Removes a component from its soonest scheduled update.
   # the component may still be updated at a later cycle.
   # see remove_all_updates to remove a component from all scheduled updates.
   def remove_update(component)
      @update_map.sort.each do |pair|
         return pair[0] if pair[1].delete? component
      end
   end

   # Removes a component from all scheduled updates.
   # The component will no longer update unless its inputs are changed.
   def remove_all_updates(component)
      @update_map.each do |k, v|
         v.delete component
      end
   end

   # Returns whether there are any scheduled updates
   def has_updates?
      !@update_map.empty?
   end

   # Adds a component to the circuit
   def add_component(component)
      add_to(component, @components)
   end

   # Removes a component from the circuit
   def remove_component(component)
      remove_all_updates component
      remove_from(component, @components)
   end

   def add_wire(wire)
      add_to(wire, @wires)
   end
   def remove_wire(wire)
      remove_from(wire, @wires)
   end

   def component_at(x, y)
      components.each do |comp|
         bounds = comp.bounds
         return comp if x >= bounds[0] && x <= bounds[0]+bounds[2] &&
                        y >= bounds[1] && y <= bounds[1]+bounds[3]
      end
      return nil
   end

   def components_within(rect)
      rect = Gdk::Rectangle.new(*rect) if rect.is_a? Array
      components.select do |comp|
         (Gdk::Rectangle.new(*comp.bounds) & rect) != nil
      end
   end
private
   def add_to(object, list)
      object.id = list.size
      list << object
      self.changed = true
   end
   def remove_from(object, list)
      id = object.id
      list.last.id = id
      list[id], list[-1] = list[-1], list[id]
      list.pop
      self.changed = true
   end
end

end
