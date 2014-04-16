require 'gtk2'

module Circuits

class Wire
   attr_reader :circuit, :input, :output, :comp_in, :comp_out, :points
   attr_accessor :id

   def initialize(component, input)
      @input = input
      @comp_in = component
      @points = [component.abs_input_pos(input)]
      @circuit = component.circuit
      @id = -1
      @circuit.add_wire self if @circuit
   end

   def connect(component, output)
      @output = output
      @comp_out = component
      add(component.abs_output_pos(output))
      @comp_in.connect_input(self)
   end

   def delete
      @circuit.remove_wire self if @circuit
   end

   def add(point)
      @points << point
   end

   def remove
      (@points.pop if @points.length > 1) != nil
   end

   def draw(cr)
      cr.set_source_rgb(0.0, 0.0, 0.0)
      cr.set_line_cap(Cairo::LINE_CAP_ROUND)
      cr.set_line_join(Cairo::LINE_JOIN_ROUND)

      cr.circle *points.first, 2
      cr.fill

      cr.move_to *points.first
      points[1..-1].each { |p| cr.line_to *p }
      cr.stroke

      cr.circle *points.last, 2
      cr.fill
   end
end

end
