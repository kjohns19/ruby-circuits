require 'gtk2'

require_relative '../application'

module Circuits

module Display

class ToolMenu < Gtk::Toolbar
   def initialize(display)
      super()
      @display = display

      button = Gtk::ToolButton.new(Gtk::Stock::NEW)
      button.signal_connect('clicked') { Circuits::Application.new_circuit }
      self.insert(-1, button)

      button = Gtk::ToolButton.new(Gtk::Stock::OPEN)
      button.signal_connect('clicked') { Circuits::Application.load_circuit }
      self.insert(-1, button)

      button = Gtk::ToolButton.new(Gtk::Stock::SAVE)
      button.signal_connect('clicked') { Circuits::Application.save_circuit }
      self.insert(-1, button)

      self.insert(-1, Gtk::SeparatorToolItem.new)


      button = Gtk::ToolButton.new(Gtk::Stock::GO_FORWARD)
      button.signal_connect('clicked') do
         @display.update
      end
      button.tooltip_text = 'Update circuit'
      self.insert(-1, button)

      speed = Gtk::SpinButton.new(10, 10000, 1)
      speed.value = 500

      thread = nil
      button = Gtk::ToggleToolButton.new(Gtk::Stock::MEDIA_PLAY)
      button.signal_connect('clicked') do |button|
         if thread.nil?
            #button.label = "Stop"
            button.stock_id = Gtk::Stock::MEDIA_PAUSE
            thread = Thread.new do
               loop do
                  Gtk.queue {@display.update}
                  sleep(speed.value/1000.0)
               end
            end
         else
            #button.label = "Run"
            button.stock_id = Gtk::Stock::MEDIA_PLAY
            thread.kill
            thread = nil
         end
      end
      button.tooltip_text = 'Run circuit'
      speed.tooltip_text = 'Update speed (ms)'
      self.insert(-1, button)

      speed_item = Gtk::ToolItem.new
      speed_item.add(speed)
      self.insert(-1, speed_item)

      self.insert(-1, Gtk::SeparatorToolItem.new)

      # Change this to add new state buttons
      # Order: Label (String), State (Class), Tooltip text (String)
      states = [
         [Gtk::Stock::ADD, ClickState::Create,
            "Create\nLMB - Create component\nRMB - Delete component"],
         [Gtk::Stock::CONNECT, ClickState::Wire,
            "Wire\nLMB - Wire input to output\nRMB - Remove input wire"],
         [Gtk::Stock::EDIT,   ClickState::Edit,
            "Edit\nLMB - Change properties"],
         [Gtk::Stock::REFRESH, ClickState::Update,
            "Update\nLMB - Update inputs/outputs on selected component"]
      ]

      buttons = []
      toggle_ids = []
      click_ids = []

      # This jumbled mess sets up the state buttons
      # All this code is to make sure only one is selected...
      states.each_with_index do |state, i|
         button = Gtk::ToggleToolButton.new(state[0])

         # Signals - toggled and clicked. Only one can be used at a time

         # Signal that selects the state
         # This deselects the previous button and selects this one
         signal = button.signal_connect('toggled') do |button|
            buttons.each_with_index do |b, j|
               next unless b.active? && b != button
               b.signal_handler_block click_ids[j]
               b.active = false
               b.signal_handler_unblock toggle_ids[j]
            end
            button.signal_handler_block toggle_ids[i]
            button.signal_handler_unblock click_ids[i]
            @display.click_state = states[i][1].new(@display)
         end
         toggle_ids << signal
         # This signal is blocked by selected button
         button.signal_handler_block signal if i == 0

         # Signal that ensures the selected button is still selected
         # Even when clicked again
         signal = button.signal_connect('clicked') do |button|
            button.active = true
         end
         click_ids << signal
         # This signal is blocked by all buttons except the one selected
         button.signal_handler_block signal unless i == 0

         button.tooltip_text = state[2]
         buttons << button

         #button_item = Gtk::ToolItem.new
         #button_item.add(button)
         self.insert(-1, button)
      end

      # Select first mode
      buttons[0].active = true


      #self.insert(-1, Gtk::SeparatorToolItem.new)

      #button = Gtk::ToolButton.new(Gtk::Stock::COPY)
      #button.signal_connect('clicked') do
      #   load "#{Dir.pwd}/display/component_display.rb"
      #   @display.repaint
      #end
      #self.insert(-1, button)
   end
end

end

end
