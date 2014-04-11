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
            comp.position = [event.x, event.y]
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
            @area.click_state = WireIn.new(@area, comp, i)
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

   def initialize(area, component, input)
      super(area)
      @component = component
      @input = input
   end

   def click(event)
      case event.button
      when 1
         @area.show_wire_menu(event, false) do |comp, i|
            @component.connect_input(@input, comp, i)
            @area.redraw
            @area.click_state = Wire.new(@area)
         end
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
