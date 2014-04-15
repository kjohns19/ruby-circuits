require_relative '../component/wire'

module Circuits

module Display

module ClickState

class Base
   def initialize(app, area)
      @app
      @area = area
   end

   def click(event)
   end

   def move(window, x, y, state)
   end
end

class Create < Base
   def click(event)
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
      @area.snap *@area.from_screen(x, y-ComponentArea::GRID_SIZE)
   end
end

class Wire < Base
   def click(event)
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
      case event.button
      when 1
         valid = @area.show_wire_menu(event, false) do |comp, i|
            @wire.connect(comp, i)
            @wire.comp_in.connect_input(@wire)
            @area.repaint { |cr| @wire.draw(cr) }
            @area.click_state = Wire.new(@app, @area)
         end
         unless valid
            @wire.add(@area.snap *@area.from_screen(event.x, event.y))
            @area.repaint { |cr| @wire.draw(cr) }
         end
      when 3
         @wire.remove
         @area.repaint { |cr| @wire.draw(cr) }
      end
   end

   def move(window, x, y, state)
      @area.repaint do |cr|
         @wire.add(@area.snap *@area.from_screen(x, y))
         @wire.draw(cr)
         @wire.remove
      end
   end
end

class Edit < Base
   def click(event)
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
      return unless event.button == 1

      comp = @area.component_at *@area.from_screen(event.x, event.y)
      return if comp.nil?

      comp.update_inputs
      comp.update_outputs
      @area.repaint
   end
end

class Move < Base
   def click(event)
      if event.button == 1
         @mouse = [event.x, event.y]
         @start_pos = @area.position
      end
   end

   def move(window, x, y, state)
      if (state & Gdk::Window::BUTTON1_MASK) != 0
         dif = [x-@mouse[0], y-@mouse[1]]
         @area.position = [@start_pos[0]-dif[0], @start_pos[1]-dif[1]]
      else
         @mouse_pos = nil
         @start_pos = nil
      end

   end
end

end

end

end
