require 'gtk2'

module Circuits

module Display

class ComponentArea < Gtk::Frame
   
   def initialize
      super
      @draw_area = Gtk::DrawingArea.new
      @draw_area.set_size_request(500, 500)
      @draw_area.signal_connect("expose_event") { redraw }

      @draw_area.signal_connect('button_press_event') do |*args|
         button_press(*args)
      end

      @draw_area.events |= Gdk::Event::BUTTON_PRESS_MASK

      self.add(@draw_area)
   end

   def circuit=(circuit)
      @circuit = circuit
      redraw
   end
   attr_reader :circuit
   attr_accessor :editor

   def redraw
      window = @draw_area.window
      return if window.nil?

      cr = window.create_cairo_context

      alloc = @draw_area.allocation

      cr.set_source_rgb 1.0, 1.0, 1.0
      cr.rectangle 0, 0, alloc.width, alloc.height
      cr.fill

      return if @circuit.nil?

      @circuit.components.each do |comp|
         cr.save
         cr.translate *comp.position
         draw_component(comp, cr)
         cr.restore
      end
   end

   def draw_component(component, cr)
      num_ports = [component.input_count, component.output_count, 1].max

      width = 50
      height = 15*(num_ports+1)

      cr.set_source_rgb 1.0, 1.0, 1.0
      cr.rounded_rectangle 0, 0, width, height, 12
      cr.fill_preserve
      cr.set_source_rgb 0.0, 0.0, 0.0
      cr.stroke

      cr.select_font_face('Arial', 'normal', 'bold')

      label = component.label
      extents = cr.text_extents(label)
      x = width/2 - (extents.width/2 + extents.x_bearing)
      y = height/2 - (extents.height/2 + extents.y_bearing)

      cr.move_to x, y
      cr.show_text component.label
   end

   def button_press(widget, event)
      puts "Pressed button #{event.button}"
      puts "Mouse at (#{event.x}, #{event.y})"
      
      return true if @editor.nil?

      comp = @editor.create_component(@circuit)
      return true if comp.nil?

      comp.position = [event.x, event.y]

      redraw
      return true
   end
end

end

end
