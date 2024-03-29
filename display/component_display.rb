require_relative 'component_area'

module Circuits

module Display

module ComponentDisplay
   WIDTH       = 3
   PORT_SEP    = 1
   PORT_OFFSET = 1
   PORT_RADIUS = 0.15
   PORT_INSET  = 0
   RECT_RADIUS = 0.25
   RECT_OFFSET = 0.7
   LINE_WIDTH  = 0.1

   attr_accessor :debug
   attr_accessor :invert

   def draw(cr)
      width, height = self.size

      cr.set_line_width(LINE_WIDTH)
      cr.set_source_rgb(1.0, 1.0, 1.0)
      cr.rounded_rectangle(0, RECT_OFFSET,
                           width, height-2*RECT_OFFSET,
                           RECT_RADIUS)
      cr.fill_preserve
      cr.set_source_rgb(0.0, 0.0, 0.0)
      cr.stroke

      cr.select_font_face('Arial', 'normal', 'bold')

      funcs = [['input', !invert], ['output', invert]]

      funcs.each do |(pref, label_move)|
         self.send("#{pref}_count").times do |i|
            cr.set_source_rgb(1.0, 1.0, 1.0)
            pos = self.send("#{pref}_pos", i)
            cr.circle(pos[0], pos[1], PORT_RADIUS)
            cr.fill
            cr.set_source_rgb(0.0, 0.0, 0.0)
            cr.circle(pos[0], pos[1], PORT_RADIUS)
            cr.stroke

            cr.set_font_size 0.5
            cr.set_source_rgb(0.0, 0.0, 0.0)
            label = self.send("#{pref}_label", i)
            extents = cr.text_extents(label)
            x = label_move ? (pos[0]+0.3) : (pos[0]-0.3-extents.width)
            y = pos[1]+0.15

            cr.move_to(x,y)
            cr.show_text(label)
         end
      end
      draw_label(cr)
   end

   def draw_label(cr)
      width, height = self.size
      label = self.label
      extents = cr.text_extents(label)
      x = width/2.0 - (extents.width/2 + extents.x_bearing)
      y = 0.5
      cr.move_to(x, y)
      cr.show_text label
   end

   def draw_values(cr)
      return unless self.debug

      cr.set_font_size(0.5)
      draw = lambda do |pos, i, values, move_text|
         text = self.send(values)[i].inspect
         
         extents = cr.text_extents(text)
         x = move_text ? (pos[0]-0.5-extents.width) : (pos[0]+0.5)
         y = pos[1] - (extents.height/2 + extents.y_bearing)

         b = 0.15
         cr.set_source_rgb(0.9, 0.9, 0.9)
         cr.rectangle(x-b, y-extents.height-b,
                        extents.width+extents.x_bearing+b*2, extents.height+b*2)
         cr.fill

         cr.set_source_rgb(0.0, 0.0, 0.0)
         cr.move_to(x, y)
         cr.show_text text
      end

      input_ports_each { |pos, i| draw.call(pos, i, :inputs_current, !invert) }
      output_ports_each{ |pos, i| draw.call(pos, i, :outputs, invert) }
   end

   def input_ports_each
      self.input_count.times do |i|
         yield input_pos(i), i
      end
   end
   def output_ports_each
      self.output_count.times do |i|
         yield output_pos(i), i
      end
   end

   def bounds
      [*self.position, *self.size]
   end

   def ports
      [self.input_count, self.output_count, 1].max
   end

   def size
      [WIDTH, 2*PORT_OFFSET + PORT_SEP*(self.ports-1)]
   end

   def input_pos(input)
      [invert ? (WIDTH-PORT_INSET) : PORT_INSET, PORT_OFFSET + PORT_SEP*input]
   end

   def output_pos(output)
      [invert ? PORT_INSET : WIDTH-PORT_INSET, PORT_OFFSET + PORT_SEP*output]
   end

   def abs_input_pos(input)
      pos = self.position
      port = self.input_pos(input)
      [pos[0]+port[0], pos[1]+port[1]]
   end
   def abs_output_pos(output)
      pos = self.position
      port = self.output_pos(output)
      [pos[0]+port[0], pos[1]+port[1]]
   end
end


end

end
