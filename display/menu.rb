require 'gtk2'

module Circuits

module Display

class Menu < Gtk::HBox
   def initialize(display)
      super()
      @display = display

      button = Gtk::Button.new("Step")
      button.signal_connect('clicked') do
         @display.update
      end
      button.width_request = 60
      button.tooltip_text = 'Update circuit'
      self.pack_start(button, false, false)

      speed = Gtk::SpinButton.new(100, 10000, 1)
      speed.value = 500

      thread = nil
      button = Gtk::Button.new("Run")
      button.signal_connect('clicked') do |button|
         if thread.nil?
            button.label = "Stop"
            thread = Thread.new do
               loop do
                  Gtk.queue {@display.update}
                  sleep(speed.value/1000.0)
               end
            end
         else
            button.label = "Run"
            thread.kill
            thread = nil
         end
      end
      button.tooltip_text = 'Repeatedly update circuit'
      speed.tooltip_text = 'Update speed (ms)'
      button.width_request = 60
      speed.width_request = 60
      self.pack_start(button, false, false)
      self.pack_start(speed, false, false)

      sep = Gtk::VSeparator.new
      sep.width_request = 20

      self.pack_start(sep, false, false)

      # Change this to add new state buttons
      # Order: Label (String), State (Class), Tooltip text (String)
      states = [
         ['Create', ClickState::Create,
            "LMB - Create component\nRMB - Delete component"],
         ['Wire',   ClickState::Wire,
            "LMB - Wire input to output\nRMB - Remove input wire"],
         ['Edit',   ClickState::Edit,
            "LMB - Change properties"],
         ['Update', ClickState::Update,
            "LMB - Update inputs/outputs on selected component"]
      ]

      buttons = []
      toggle_ids = []
      click_ids = []

      # This jumbled mess sets up the state buttons
      # All this code is to make sure only one is selected...
      # DON'T TOUCH THIS!
      states.each_with_index do |state, i|
         button = Gtk::ToggleButton.new(state[0])

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
         button.width_request = 60
         buttons << button
         self.pack_start(button, false, false)
      end

      # Select first mode
      buttons[0].active = true
   end
end

end

end
