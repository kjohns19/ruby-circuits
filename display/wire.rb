require 'gtk2'

module Circuits

module Display

class Wire
   attr_reader :points

   def initialize(circuit, start)
      @points = [start]#path(circuit, start, finish)
   end

   def add(point)
      @points << point
   end

   def remove
      @points.pop if @points.length > 1
   end

   def path(circuit, start, finish)
      [start, finish]
   end

   def draw(cr)
      cr.set_source_rgb(0.0, 0.0, 0.0)
      cr.set_line_cap(Cairo::LINE_CAP_ROUND)
      cr.set_line_join(Cairo::LINE_JOIN_ROUND)

      cr.circle *points.first, 3
      cr.fill

      cr.move_to *points.first
      points[1..-1].each { |p| cr.line_to *p }
      cr.stroke

      cr.circle *points.last, 3
      cr.fill
   end
end

end

end
