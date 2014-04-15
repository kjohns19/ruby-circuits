require_relative 'click_state.rb'

module Circuits

module Display

class ComponentArea < Gtk::Frame
   GRID_SIZE = 20
   
   def initialize(app)
      super()
      @app = app

      @draw_area = Gtk::DrawingArea.new
      @draw_area.set_size_request(GRID_SIZE*25, GRID_SIZE*25)
      @draw_area.signal_connect('expose_event') do |area, event|
         redraw(event.area.to_a)
      end

      @draw_area.signal_connect('button_press_event') do |*args|
         button_press(*args)
      end
      @draw_area.signal_connect('motion_notify_event') do |*args|
         button_move(*args)
      end

      @draw_area.events |= Gdk::Event::BUTTON_PRESS_MASK |
                           Gdk::Event::POINTER_MOTION_MASK |
                           Gdk::Event::POINTER_MOTION_HINT_MASK

      @click_state = ClickState::Create.new(@app, self)

      @position = [0,0]

      self.add(@draw_area)
      self.show_grid = true
   end

   def circuit=(circuit)
      @circuit = circuit
      repaint
   end
   attr_reader :circuit
   attr_accessor :click_state
   attr_accessor :editor
   attr_reader :position

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

      if clip.nil?
         alloc = @draw_area.allocation
         clip = [0, 0, alloc.width, alloc.height]
      end
      clip[0]+=position[0]
      clip[1]+=position[1]

      clip = Gdk::Rectangle.new *clip

      cr.translate -position[0], -position[1]

      if @show_grid
         cr.save do
            #cr.translate offset stuff here
            draw_grid(cr, clip)
         end
      else
         cr.set_source_rgb(1.0, 1.0, 1.0)
         cr.rectangle *clip.to_a
         cr.fill
      end

      return if @circuit.nil?

      components_draw(cr, clip, :draw)
      components_draw(cr, clip, :draw_wires, false)
      components_draw(cr, clip, :draw_values)

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
      @click_state.click(event)
      return true
   end
   def button_move(widget, event)
      win, x, y, state = event.window.pointer
      @click_state.move(win, x, y, state)
      return true
   end

   def snap(x, y)
      [(x.to_i+GRID_SIZE/2)/GRID_SIZE*GRID_SIZE,
       (y.to_i+GRID_SIZE/2)/GRID_SIZE*GRID_SIZE]
   end

   def from_screen(x, y)
      [x+position[0], y+position[1]]
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
      w = clip.width.to_i/GRID_SIZE+2
      h = clip.height.to_i/GRID_SIZE+2

      @grid_image = Cairo::ImageSurface.from_png('data/grid_cell.png')
      pattern = Cairo::SurfacePattern.new(@grid_image)
      pattern.set_extend(Cairo::EXTEND_REPEAT)
      cr.scale(GRID_SIZE, GRID_SIZE)

      matrix = Cairo::Matrix.scale(GRID_SIZE, GRID_SIZE)
      pattern.set_matrix(matrix)

      cr.set_source(pattern)
      cr.rectangle clip.x/GRID_SIZE, clip.y/GRID_SIZE, w, h
      cr.fill
   end
end

end

end
