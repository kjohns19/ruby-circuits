require 'gtk2'

module Circuits

class Wire
   attr_reader :input, :output, :comp_in, :comp_out, :points
   attr_accessor :id

   def initialize(component, input)
      @input = input
      @comp_in = component
      @points = [component.abs_input_pos(input)]
      @id = -1
      component.circuit.add_wire self if component.circuit
   end

   def position
      @points.first
   end
   def position=(position)
      mypos = self.position
      diff = [position[0]-mypos[0], position[1]-mypos[1]]
      move(diff)
   end
   def move(amount)
      @points.map! {|a| [amount[0]+a[0], amount[1]+a[1]] }
   end

   def connect(component, output)
      @output = output
      @comp_out = component
      add(component.abs_output_pos(output))
      @comp_in.connect_input(self)
   end

   def translate(amount)
      points.map! { |p| [p[0]+amount[0], p[1]+amount[1]] }
   end

   def delete
      @comp_in.circuit.remove_wire self if @comp_in.circuit
   end

   def add(point)
      @points << point
   end

   def remove
      (@points.pop if @points.length > 1) != nil
   end

   def draw(cr)
      if comp_in.circuit.nil?
         puts "Why am I nil?"
         puts self
         exit
      end
      cr.set_source_rgb(*color)
      cr.set_line_cap(Cairo::LINE_CAP_ROUND)
      cr.set_line_join(Cairo::LINE_JOIN_ROUND)
      cr.set_line_width(0.1)

      cr.circle *points.first, 0.1
      cr.fill

      cr.move_to *points.first
      points[1..-1].each { |p| cr.line_to *p }
      cr.stroke

      cr.circle *points.last, 0.1
      cr.fill
   end

   def color
      return [0, 0, 0] if comp_out.nil?
      value = comp_out.outputs[output]
      return [1, 0, 0] if value == false
      return [0, 1, 0] if value == true
      return [0, 0, 0]
   end
end

end
