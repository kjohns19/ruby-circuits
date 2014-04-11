require 'gtk2'

require_relative 'click_state.rb'

module Circuits

module Display

class ComponentArea < Gtk::Frame
   
   def initialize
      super
      @draw_area = Gtk::DrawingArea.new
      @draw_area.set_size_request(500, 500)
      @draw_area.signal_connect('expose_event') { redraw }

      @draw_area.signal_connect('button_press_event') do |*args|
         button_press(*args)
      end

      @draw_area.events |= Gdk::Event::BUTTON_PRESS_MASK

      @click_state = ClickState::Create.new(self)

      self.add(@draw_area)
   end

   def circuit=(circuit)
      @circuit = circuit
      redraw
   end
   attr_reader :circuit
   attr_accessor :click_state
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
         comp.draw(cr)
         cr.restore
      end
      @circuit.components.each do |comp|
         cr.save
         cr.translate *comp.position
         comp.draw_wires(cr)
         cr.restore
      end
      @circuit.components.each do |comp|
         cr.save
         cr.translate *comp.position
         comp.draw_values(cr)
         cr.restore
      end
   end

   def component_at(x, y)
      return nil if @circuit.nil?

      @circuit.components.each do |comp|
         bounds = comp.bounds
         return comp if x >= bounds[0] && x <= bounds[0]+bounds[2] &&
                        y >= bounds[1] && y <= bounds[1]+bounds[3]
      end
      return nil
   end

   def button_press(widget, event)
      @click_state.click(event)

      return true
   end

   
   def show_wire_menu(event, inputs, &block)
      comp = component_at(event.x, event.y)
      return if comp.nil?

      menu = Gtk::Menu.new

      count, label = inputs ? [comp.input_count, :input_label] :
                               [comp.output_count, :output_label]

      return if count.zero?

      menu = Gtk::Menu.new

      count.times do |i|
         item = Gtk::MenuItem.new(comp.send(label, i))
         item.signal_connect('activate') do |widget|
            block.call(comp, i)
         end
         menu.append(item)
      end

      menu.show_all
      menu.popup(nil, nil, event.button, event.time)
   end

   def update
      return if @circuit.nil?
      @circuit.update
      redraw
   end
end

end

end
