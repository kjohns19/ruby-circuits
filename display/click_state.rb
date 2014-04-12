require_relative 'wire'

module Circuits

module Display

module ClickState

class Base
   def initialize(area)
      @area = area
   end
end

class Create < Base
   def click(event)
      case event.button
      when 1
         comp = @area.editor.create_component(@area.circuit)
         unless comp.nil?
            comp.position = @area.snap(event.x, event.y)
            p comp.position
            @area.redraw
         end
      when 3
         comp = @area.component_at(event.x, event.y)
         unless comp.nil?
            comp.delete
            @area.redraw
         end
      end
   end
end

class Wire < Base
   def click(event)
      case event.button
      when 1
         @area.show_wire_menu(event, true) do |comp, i|
            wire = Display::Wire.new(@area.circuit, comp.abs_input_pos(i))
            @area.click_state = WireIn.new(@area, comp, i, wire)
         end
      when 3
         @area.show_wire_menu(event, true) do |comp, i|
            comp.disconnect_input(i)
            @area.redraw
         end
      end
   end
end

class WireIn < Base
   attr_reader :component, :input

   def initialize(area, component, input, wire)
      super(area)
      @component = component
      @input = input
      @wire = wire
   end

   def click(event)
      case event.button
      when 1
         valid = @area.show_wire_menu(event, false) do |comp, i|
            @wire.add(comp.abs_output_pos(i))
            @component.connect_input(@input, comp, i, @wire)
            @area.redraw { |cr| @wire.draw(cr) }
            @area.click_state = Wire.new(@area)
         end
         unless valid
            @wire.add(@area.snap(event.x, event.y))
            @area.redraw { |cr| @wire.draw(cr) }
         end
      when 3
         @wire.remove
         @area.redraw { |cr| @wire.draw(cr) }
      end
   end
end

class Edit < Base
   def click(event)
      return unless event.button == 1

      comp = @area.component_at(event.x, event.y)
      return if comp.nil?

      editor = ComponentEditor.new
      editor.load_properties(comp)

      dialog = Gtk::Dialog.new(
                  "Change Properties", $main_application_window,
                  Gtk::Dialog::MODAL | Gtk::Dialog::DESTROY_WITH_PARENT,
                  [Gtk::Stock::OK, Gtk::Dialog::RESPONSE_ACCEPT],
                  [Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_REJECT])
      dialog.signal_connect('response') do |dialog, id|
         if id == Gtk::Dialog::RESPONSE_ACCEPT
            editor.save_properties(comp)
            @area.redraw
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

      comp = @area.component_at(event.x, event.y)
      return if comp.nil?

      comp.update_inputs
      comp.update_outputs
      @area.redraw
   end
end

end

end

end
