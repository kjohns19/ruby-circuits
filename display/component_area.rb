require_relative 'click_state.rb'
require_relative '../util/rectangle'

module Circuits

module Display

class ComponentArea < Gtk::Frame
   GRID_MAX = 40
   GRID_MIN = 5

   attr_reader :circuit
   attr_accessor :click_state
   attr_accessor :editor
   attr_reader :position
   attr_accessor :running
   attr_reader :grid_size

   def grid_size=(size)
      return unless size.between?(GRID_MIN, GRID_MAX) && size != @grid_size
      @grid_size = size
      @grid_image = nil
      repaint
   end
   
   def initialize(app)
      super()
      @app = app

      @grid_size = 20

      @draw_area = Gtk::DrawingArea.new
      @draw_area.set_size_request(500, 500)
      @draw_area.signal_connect('expose_event') do |area, event|
         redraw(event.area.to_a)
      end

      @draw_area.signal_connect('button_press_event') do |*args|
         button_press(*args)
      end
      @draw_area.signal_connect('button_release_event') do |*args|
         button_release(*args)
      end
      @draw_area.signal_connect('motion_notify_event') do |*args|
         button_move(*args)
      end

      @draw_area.events |= Gdk::Event::BUTTON_PRESS_MASK |
                           Gdk::Event::BUTTON_RELEASE_MASK |
                           Gdk::Event::POINTER_MOTION_MASK |
                           Gdk::Event::POINTER_MOTION_HINT_MASK

      @click_state = ClickState::Create.new(@app, self)
      @run_state = ClickState::Run.new(@app, self)

      @position = [0,0]

      self.add(@draw_area)
      self.show_grid = true
   end

   def circuit=(circuit)
      @circuit = circuit
      repaint
   end

   def position=(position)
      return if @position == position
      @position = position
      repaint
   end

   def repaint(clip = nil, &block)
      alloc = @draw_area.allocation
      if clip.nil?
         clip = [0, 0, alloc.width, alloc.height]
      end
      
      @redraw_block = block
      @draw_area.queue_draw_area(*clip)
   end

   def redraw(clip = nil)
      window = @draw_area.window
      return if window.nil?

      cr = window.create_cairo_context
      cr.scale(grid_size.to_f, grid_size.to_f)

      clip[2]/=grid_size.to_f
      clip[3]/=grid_size.to_f
      clip[0]+=position[0]-clip[2]/2.0
      clip[1]+=position[1]-clip[3]/2.0

      clip = Rectangle.new *clip
      cr.translate -clip.x, -clip.y


      if @show_grid
         cr.save do
            draw_grid(cr, clip)
         end
      else
         cr.set_source_rgb(1.0, 1.0, 1.0)
         cr.rectangle *clip.to_a
         cr.fill
      end

      return if @circuit.nil?

      components_draw(cr, clip, :draw)
      #components_draw(cr, clip, :draw_wires, false)
      components_draw(cr, clip, :draw_values)

      @circuit.wires.each do |wire|
         cr.save do
            wire.draw(cr)
         end
      end

      unless @redraw_block.nil?
         cr.save do
            @redraw_block.call(cr)
            @redraw_block = nil
         end
      end
   end

   def component_at(x, y)
      @circuit.nil? ? nil : @circuit.component_at(x,y)
   end

   def button_press(widget, event)
      if running
         @run_state.click(event)
      else
         @click_state.click(event)
      end
      return true
   end
   def button_release(widget, event)
      if running
         @run_state.release(event)
      else
         @click_state.release(event)
      end
      return true
   end
   def button_move(widget, event)
      win, x, y, state = event.window.pointer
      if running
         @run_state.move(win, x, y, state)
      else
         @click_state.move(win, x, y, state)
      end
      return true
   end

   def snap(x, y)
      [(x.to_f+0.5).floor,
       (y.to_f+0.5).floor]
   end

   def from_screen(x, y)
      alloc = @draw_area.allocation
      [(x.to_f-alloc.width/2.0)/grid_size+position[0],
       (y.to_f-alloc.height/2.0)/grid_size+position[1]]
   end

   def snap_from_screen(x, y)
      self.snap *self.from_screen(x, y)
   end

   
   def show_wire_menu(event, inputs, &block)
      comp = component_at *from_screen(event.x, event.y)
      return false if comp.nil?

      menu = Gtk::Menu.new

      count, label = inputs ? [comp.input_count, :input_label] :
                               [comp.output_count, :output_label]

      return false if count.zero?

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

   def show_grid=(show)
      return if show == @show_grid
      @show_grid = show
      repaint
   end
   attr_reader :show_grid

private

   def components_draw(cr, clip, name, translate = true)
      @circuit.components_within(clip).each do |comp|
         cr.save do
            cr.translate *comp.position if translate
            comp.send(name, cr)
         end
      end
   end

   def draw_grid(cr, clip)
      if @grid_image.nil?
         begin
            # Load the correct image
            @grid_image = Cairo::ImageSurface.from_png("data/grid_cell_#{grid_size}.png")
         rescue
            # If the image isn't found, we must make our own
            @grid_image = Cairo::ImageSurface.new(grid_size, grid_size)
            g = Cairo::Context.new(@grid_image)
            g.set_source_rgb(1, 1, 1)
            g.rectangle(0, 0, grid_size, grid_size)
            g.fill
            g.set_source_rgb(0.9, 0.9, 0.9)
            g.move_to(0, 0)
            g.line_to(grid_size, 0)
            g.stroke
            g.move_to(0, 0)
            g.line_to(0, grid_size)
            g.stroke
         end
      end


      pattern = Cairo::SurfacePattern.new(@grid_image)
      pattern.set_extend(Cairo::EXTEND_REPEAT)

      matrix = Cairo::Matrix.scale(grid_size, grid_size)
      pattern.set_matrix(matrix)

      cr.set_source(pattern)
      cr.rectangle clip.x-1, clip.y-1, clip.width+2, clip.height+2
      cr.fill
   end
end

end

end
