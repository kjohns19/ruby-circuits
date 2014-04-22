require 'gtk2'

require_relative 'application'
require_relative '../display/click_state'

module Circuits

module Gui

class Toolbar < Gtk::Toolbar
   attr_reader :tool_buttons
   attr_reader :run_button, :step_button, :speed_button
   def initialize(app)
      super()
      # Update speed spinner
      speed = Gtk::SpinButton.new(10, 10000, 1)
      speed.value = 500
      speed.tooltip_text = 'Update speed (ms)'
      @speed_button = speed
      speed_item = Gtk::ToolItem.new
      speed_item.add(speed)

      buttons = [
         # New, Load, and Save
         [Gtk::Stock::NEW, proc { app.new_circuit }, 'New circuit'],
         [Gtk::Stock::OPEN, proc { app.load_circuit }, 'Open circuit'],
         [Gtk::Stock::SAVE, proc { app.save_circuit }, 'Save circuit'],

         [Gtk::SeparatorToolItem.new],
         [Application::STOCK_IMPORT, proc { app.import_circuit }, 'Import circuit'],
         [Gtk::SeparatorToolItem.new],

         # Undo / Redo
         [Gtk::Stock::UNDO, proc { app.undo }, 'Undo', proc { |b| b.sensitive = false }],
         [Gtk::Stock::REDO, proc { app.redo }, 'Redo', proc { |b| b.sensitive = false }],

         [Gtk::SeparatorToolItem.new],

         # Step, Run, and Speed
         [Gtk::Stock::MEDIA_FORWARD, proc { app.step_update }, 'Update circuit',
               proc { |b| @step_button = b }],
         [Gtk::Stock::MEDIA_PLAY, proc { app.toggle_update(speed.value) },
               'Run circuit', proc { |b| @run_button = b }],
         [speed_item],

         [Gtk::SeparatorToolItem.new],
      ]

      buttonproc = proc do |(stock, func, tooltip, block)|
         if func.nil?
            self.insert(-1, stock)
         else
            button = Gtk::ToolButton.new(stock)
            button.signal_connect('clicked', &func)
            button.tooltip_text = tooltip
            block.call(button) if block
            self.insert(-1, button)
         end
      end
      
      buttons.each(&buttonproc)

      @tool_buttons = {}

      # Change this to add new state buttons
      # Order: Label (String), State (Class), Tooltip text (String)
      states = [
         [Application::STOCK_TOOL_CREATE, Circuits::Display::ClickState::Create,
            "Create\nLMB - Create component\nRMB - Delete component"],
         [Application::STOCK_TOOL_WIRE, Circuits::Display::ClickState::Wire,
            "Wire\nLMB - Wire input to output\nRMB - Remove input wire"],
         [Application::STOCK_TOOL_EDIT,   Circuits::Display::ClickState::Edit,
            "Edit\nLMB - Change properties"],
         [Application::STOCK_TOOL_UPDATE, Circuits::Display::ClickState::Update,
            "Update\nLMB - Update inputs/outputs on selected component"],
         [Application::STOCK_TOOL_DEBUG, Circuits::Display::ClickState::Debug,
            "Debug\nLMB - Toggle showing inputs/outputs"]
      ]

      button = nil
      states.each_with_index do |(id, state, text), i|
         button = Gtk::RadioToolButton.new(button, id)

         button.signal_connect('toggled') do |button|
            app.tool = state if button.active?
         end
         button.tooltip_text = text

         self.insert(-1, button)
         @tool_buttons[state] = button

         # Select first tool
         button.active = true if i.zero?
      end

      buttons = [
         [Gtk::SeparatorToolItem.new],
         [Gtk::Stock::ZOOM_OUT, proc { app.display.grid_size/=2 }, 'Zoom Out'],
         [Gtk::Stock::ZOOM_IN, proc { app.display.grid_size*=2 }, 'Zoom In'],
      ]

      buttons.each(&buttonproc)
   end
end

end

end
