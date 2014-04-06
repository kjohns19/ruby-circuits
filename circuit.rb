require 'set'

# Main module for all circuit classes
module Circuits

# Container for components
# Circuits keeps track of which components need inputs/outputs updated
# based on the previous update.
class Circuit
   attr_reader :components

   # Initializes a new circuit
   def initialize
      @components = Set.new
      @update_map = {}
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
   def add(component)
      @components << component
   end

   # Removes a component from the circuit
   def remove(component)
      remove_all_updates component
      @components.delete component
   end
end

end