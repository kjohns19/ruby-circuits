require 'gtk2'

require_relative 'click_state.rb'

module Circuits

module Display

class ComponentArea < Gtk::Frame
   
   def initialize
      super
      @draw_area = Gtk::DrawingArea.new
      @draw_area.set_size_request(500, 500)
      @draw_area.signal_connect('expose_event') do |area, event|
         redraw(event)
      end

      @draw_area.signal_connect('button_press_event') do |*args|
         button_press(*args)
      end

      @draw_area.events |= Gdk::Event::BUTTON_PRESS_MASK

      @click_state = ClickState::Create.new(self)

      self.add(@draw_area)
      self.show_grid = true
   end

   def circuit=(circuit)
      @circuit = circuit
      redraw
   end
   attr_reader :circuit
   attr_accessor :click_state
   attr_accessor :editor

   def redraw(event = nil)
      window = @draw_area.window
      return if window.nil?

      cr = window.create_cairo_context

      alloc = self.allocation

      clip = event.nil? ? [0, 0, alloc.width, alloc.height] : event.area.to_a

      cr.set_source_rgb(1.0, 1.0, 1.0)
      cr.rectangle *clip
      cr.fill

      if @show_grid
         cr.save do
            #cr.translate offset stuff here
            draw_grid(cr, clip)
         end
      end

      return if @circuit.nil?

      components_draw(cr, clip, :draw)
      components_draw(cr, clip, :draw_wires, false)
      #components_draw(cr, clip, :draw_values)
      yield cr if block_given?
   end

   def component_at(x, y)
      @circuit.nil? ? nil : @circuit.component_at(x,y)
   end

   def button_press(widget, event)
      @click_state.click(event)

      return true
   end

   def snap(x, y)
      [x.to_i/GRID_SIZE*GRID_SIZE,
       y.to_i/GRID_SIZE*GRID_SIZE]
   end

   
   def show_wire_menu(event, inputs, &block)
      comp = component_at(event.x, event.y)
      return false if comp.nil?

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
      return true
   end

   def update
      return if @circuit.nil?
      @circuit.update
      redraw
   end

   def show_grid=(show)
      return if show == @show_grid
      @show_grid = show
      redraw
   end
   attr_reader :show_grid

private
   GRID_SIZE = 16

   def components_draw(cr, clip, name, translate = true)
      @circuit.components_within(clip).each do |comp|
         cr.save do
            cr.translate *comp.position if translate
            comp.send(name, cr)
         end
      end
   end

   def draw_grid(cr, clip)
      # Optimize this to only iterate where we need to

      alloc = self.allocation

      w = alloc.width/GRID_SIZE.to_i
      h = alloc.height/GRID_SIZE.to_i

      @grid_image ||= Cairo::ImageSurface.from_png('data/grid_cell.png')
      pattern = Cairo::SurfacePattern.new(@grid_image)
      pattern.set_extend(Cairo::EXTEND_REPEAT)
      #cr.scale(1 / ::Math.sqrt(2), 1 / ::Math.sqrt(2))
      cr.scale(GRID_SIZE, GRID_SIZE)

      matrix = Cairo::Matrix.scale(GRID_SIZE*w, GRID_SIZE*h)
      pattern.set_matrix(matrix)

      cr.set_source(pattern)
      cr.rectangle(0, 0, w+1, h+1)
      cr.fill
   end
end

end

end
