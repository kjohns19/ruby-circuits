require_relative '../component/wire'
require_relative 'component_area'

module Circuits

module Display

module ClickState

class Base
   def initialize(app, area)
      @app = app
      @area = area
   end

   def click(event)
      if event.button == 2
         @mouse = get_pos(event.x, event.y)
         @start_pos = @area.position
      end
   end

   def release(event)
   end

   def move(window, x, y, state)
      pos = @area.snap_from_screen(x, y)
      @app.status = "%s - (%d, %d)" % [self.class.name.split("::").last, *pos]
      return if @start_pos.nil?
      if (state & Gdk::Window::BUTTON2_MASK) != 0
         pos = get_pos(x, y)
         dif = [pos[0]-@mouse[0], pos[1]-@mouse[1]]
         @area.position = [@start_pos[0]-dif[0], @start_pos[1]-dif[1]]
      else
         @mouse_pos = nil
         @start_pos = nil
      end
   end
   def get_pos(x, y)
      [x.to_f/@area.grid_size, y.to_f/@area.grid_size]
   end

end

class Run < Base
   def initialize(app, area)
      super
      @comps = {}
   end
   def click(event)
      super
      comp = @area.component_at *@area.from_screen(event.x, event.y)
      comp.click(event.button) if comp
      @comps[event.button] = comp
   end

   def release(event)
      comp = @comps.delete(event.button)
      comp.release(event.button) if comp
   end
end

class Create < Base
   def click(event)
      super
      case event.button
      when 1
         @comp = @area.editor.create_component(@area.circuit)
         unless @comp.nil?
            @comp.position = create_pos(event.x, event.y)
            @area.repaint
         end
      when 3
         comp = @area.component_at *@area.from_screen(event.x, event.y)
         unless comp.nil?
            comp.delete
            @area.repaint
         end
      end
   end

   def move(window, x, y, state)
      super
      return if @comp.nil?
      if (state & Gdk::Window::BUTTON1_MASK) != 0
         newpos = create_pos(x, y)
         if newpos != @comp.position
            @comp.position = newpos
            @area.repaint
         end
      else
         @comp = nil
      end
   end

   def create_pos(x, y)
      @area.snap_from_screen(x, y-@area.grid_size)
   end
end

class Wire < Base
   def click(event)
      super
      case event.button
      when 1
         @area.show_wire_menu(event, true) do |comp, i|
            wire = Circuits::Wire.new(comp, i)
            @area.click_state = WireIn.new(@app, @area, wire)
         end
      when 3
         @area.show_wire_menu(event, true) do |comp, i|
            comp.disconnect_input(i)
            @area.repaint
         end
      end
   end
end

class WireIn < Base
   attr_reader :wire

   def initialize(app, area, wire)
      super(app, area)
      @wire = wire
   end

   def click(event)
      super
      case event.button
      when 1
         valid = @area.show_wire_menu(event, false) do |comp, i|
            @wire.connect(comp, i)
            @area.repaint { |cr| @wire.draw(cr) }
            @area.click_state = Wire.new(@app, @area)
         end
         unless valid
            @wire.add(@area.snap_from_screen(event.x, event.y))
            @area.repaint { |cr| @wire.draw(cr) }
         end
      when 3
         if @wire.remove
            @area.repaint { |cr| @wire.draw(cr) }
         else
            @wire.delete
            @area.click_state = Wire.new(@app, @area)
            @area.repaint
         end
      end
   end

   def move(window, x, y, state)
      super
      @area.repaint do |cr|
         @wire.add(@area.snap_from_screen(x, y))
         @wire.draw(cr)
         @wire.remove
      end
   end
end

class Edit < Base
   def click(event)
      super
      return unless event.button == 1

      comp = @area.component_at *@area.from_screen(event.x, event.y)
      return if comp.nil?

      editor = ComponentEditor.new(@app)
      editor.load_properties(comp)

      dialog = Gtk::Dialog.new(
                  "Change Properties", $main_application_window,
                  Gtk::Dialog::MODAL | Gtk::Dialog::DESTROY_WITH_PARENT,
                  [Gtk::Stock::OK, Gtk::Dialog::RESPONSE_ACCEPT],
                  [Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_REJECT])
      dialog.signal_connect('response') do |dialog, id|
         if id == Gtk::Dialog::RESPONSE_ACCEPT
            editor.save_properties(comp)
            @area.repaint
         end
         dialog.destroy
      end

      dialog.vbox.add(editor)
      dialog.show_all
   end
end

class Update < Base
   def click(event)
      super
      return unless event.button == 1

      comp = @area.component_at *@area.from_screen(event.x, event.y)
      return if comp.nil?

      comp.update_inputs
      comp.update_outputs
      @area.repaint
   end
end

class Debug < Base
   def click(event)
      super
      return unless event.button == 1

      comp = @area.component_at *@area.from_screen(event.x, event.y)
      return if comp.nil?

      comp.debug = !comp.debug
      @area.repaint
   end
end

end

end

end
