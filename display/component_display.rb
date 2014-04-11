require 'gtk2'

module Circuits

module Display

module ComponentDisplay
   WIDTH = 64
   PORT_SEP = 16
   PORT_RADIUS = 8
   PORT_INSET = 2

   def draw(cr)
      width, height = self.size

      cr.set_source_rgb 1.0, 1.0, 1.0
      cr.rounded_rectangle 0, 0, width, height, PORT_RADIUS
      cr.fill_preserve
      cr.set_source_rgb 0.0, 0.0, 0.0
      cr.stroke

      cr.select_font_face('Arial', 'normal', 'bold')

      funcs = [[:input_count, :input_pos], [:output_count, :output_pos]]

      funcs.each do |f|
         self.send(f[0]).times do |i|
            cr.set_source_rgb 1.0, 1.0, 1.0
            pos = self.send(f[1], i)
            cr.circle pos[0], pos[1], PORT_RADIUS
            cr.fill_preserve
            cr.set_source_rgb 0.0, 0.0, 0.0
            cr.stroke
         end
      end

      label = self.label
      extents = cr.text_extents(label)
      x = width/2 - (extents.width/2 + extents.x_bearing)
      y = height/2 - (extents.height/2 + extents.y_bearing)
      cr.move_to x, y
      cr.show_text label
   end

   def draw_wires(cr)
      cr.set_source_rgb 0.0, 0.0, 0.0
      cr.set_line_cap(Cairo::LINE_CAP_ROUND)
      self.in_connections.each do |conn|
         next if conn.nil?
         comp = conn.comp_out
         pos = self.position
         cpos = comp.position

         in_pos = self.input_pos(conn.input)
         out_pos = comp.output_pos(conn.output)
         out_pos = out_pos.each_with_index.map { |n, i| n+cpos[i]-pos[i] }

         cr.move_to *in_pos
         cr.line_to *out_pos
         cr.stroke
      end
   end

   def draw_values(cr)
      funcs = [[:input_count, :input_pos, :inputs_current, true],
               [:output_count, :output_pos, :outputs, false]]

      funcs.each do |f|
         self.send(f[0]).times do |i|
            pos = self.send(f[1], i)
            text = self.send(f[2])[i].inspect

            extents = cr.text_extents(text)
            if f[3]
               x = pos[0]-14-extents.width
            else
               x = pos[0]+14
            end
            y = pos[1] - (extents.height/2 + extents.y_bearing)

            b = 3
            cr.set_source_rgb 0.9, 0.9, 0.9
            cr.rectangle x-b, y-extents.height-b,
                         extents.width+extents.x_bearing+b*2, extents.height+b*2
            cr.fill

            cr.set_source_rgb 0.0, 0.0, 0.0
            cr.move_to x, y
            cr.show_text text
         end
      end
   end

   def bounds
      [*self.position, *self.size]
   end

   def ports
      [self.input_count, self.output_count, 1].max
   end

   def size
      [WIDTH, 2*PORT_SEP*self.ports]
   end

   def input_pos(input)
      [PORT_INSET, PORT_SEP*(1+(self.ports-self.input_count)+2*input)]
   end

   def output_pos(output)
      [WIDTH-PORT_INSET, PORT_SEP*(1+(self.ports-self.output_count)+2*output)]
   end
end

end

end
