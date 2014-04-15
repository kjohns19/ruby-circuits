require 'gtk2'

require_relative 'gtk_threads'

require_relative 'circuit'
require_relative 'display/all_display'

module Circuits

class Application
   STOCK_TOOL_CREATE = :circuit_tool_create
   STOCK_TOOL_WIRE   = :circuit_tool_wire
   STOCK_TOOL_EDIT   = :circuit_tool_edit
   STOCK_TOOL_UPDATE = :circuit_tool_update
   STOCK_TOOL_MOVE   = :circuit_tool_move

   TOOL_CREATE = :create
   TOOL_WIRE   = :wire
   TOOL_EDIT   = :edit
   TOOL_UPDATE = :update
   TOOL_MOVE   = :move

   def initialize
      setup_stocks
      @window = Gtk::Window.new("Circuits")

      @window.resizable = true
      @window.border_width = 4
      @window.signal_connect('destroy') { Gtk.main_quit }

      @selector = Circuits::Display::Selector.new(self)
      @editor = Circuits::Display::ComponentEditor.new(self)

      @selector.select_callback do |comp|
         @editor.component_class = comp
      end

      @circuit = Circuits::Circuit.new

      @display = Circuits::Display::ComponentArea.new(self)
      @display.circuit = @circuit
      @display.editor = @editor

      menu = create_menu(@window)
      toolmenu = create_toolbar
      statusbar = Gtk::Statusbar.new

      vpaned = Gtk::VPaned.new
      vpaned.pack1(@selector, true, false)
      vpaned.pack2(@editor, false, false)

      hpaned = Gtk::HPaned.new
      hpaned.pack1(vpaned, false, false)
      hpaned.pack2(@display, true, false)

      table = Gtk::Table.new(1, 4, false)
      table.attach(menu, 0, 1, 0, 1, Gtk::EXPAND | Gtk::FILL, 0, 0, 0)
      table.attach(toolmenu, 0, 1, 1, 2, Gtk::EXPAND | Gtk::FILL, 0, 0, 0)
      table.attach(hpaned, 0, 1, 2, 3, Gtk::EXPAND | Gtk::FILL, Gtk::EXPAND | Gtk::FILL, 0, 0)
      table.attach(statusbar, 0, 1, 3, 4, Gtk::EXPAND | Gtk::FILL, 0, 0, 0)

      @window.add(table)

      @window.show_all
   end

   def start
      Gtk.main_with_queue 10
   end

   def exit
      Gtk.main_quit
   end

   def step_update
      @circuit.update
      @display.repaint
   end

   def run_update(speed)
      return unless @run_thread.nil?
      @run_button.stock_id = Gtk::Stock::MEDIA_PAUSE
      @speed_button.sensitive = false
      @step_button.sensitive = false
      @run_thread = Thread.new do
         loop do
            Gtk.queue { step_update }
            sleep(speed/1000.0)
         end
      end
   end

   def stop_update
      return if @run_thread.nil?
      @run_thread.kill
      @run_thread = nil
      @run_button.stock_id = Gtk::Stock::MEDIA_PLAY
      @speed_button.sensitive = true
      @step_button.sensitive = true
   end

   def undo
      message "Undo not implemented!"
   end
   def redo
      message "Undo not implemented!"
   end

   def new_circuit
      message "New not implemented!"
   end
   def load_circuit
      message "Load not implemented!"
   end
   def save_circuit
      message "Save not implemented!"
   end

   def tool=(tool)
      button = @tool_button[tool]
      return if info.nil?
      button.active = true
   end

   def message(text)
      dialog = Gtk::MessageDialog.new(@window,
                                      Gtk::Dialog::DESTROY_WITH_PARENT,
                                      Gtk::MessageDialog::INFO,
                                      Gtk::MessageDialog::BUTTONS_CLOSE,
                                      text)
      dialog.signal_connect('response') do |widget, response|
         widget.destroy
      end

      dialog.show
   end

private
   def setup_stocks
      stocks = [
         [STOCK_TOOL_CREATE, '_Create', Gtk::Stock::ADD],
         [STOCK_TOOL_WIRE, '_Wire', Gtk::Stock::CONNECT],
         [STOCK_TOOL_EDIT, '_Edit', Gtk::Stock::EDIT],
         [STOCK_TOOL_UPDATE, '_Update', Gtk::Stock::REFRESH],
         [STOCK_TOOL_MOVE, '_Move', Gtk::Stock::FULLSCREEN]
      ]

      factory = Gtk::IconFactory.new

      stocks.each do |(id, label, icon_id)|
         Gtk::Stock.add(id, label)
         set = Gtk::IconFactory.lookup_default(icon_id.to_s)
         factory.add(id.to_s, set)
      end

      factory.add_default
   end

   def create_menu(window)
      items = [
         ['/_File'],
         ['/_File/_New', '<StockItem>', '<control>N',
            Gtk::Stock::NEW, proc { self.new_circuit }],
         ['/_File/_Load', '<StockItem>', '<control>O',
            Gtk::Stock::OPEN, proc { self.load_circuit }],
         ['/_File/_Save', '<StockItem>', '<control>S',
            Gtk::Stock::SAVE, proc { self.save_circuit }],
         ['/_File/sep', '<Separator>', nil, nil, nil],
         ['/_File/_Quit', '<StockItem>', '<control>Q',
            Gtk::Stock::QUIT, proc { self.exit }],

         ['/_Tool']
      ]
      accel_group = Gtk::AccelGroup.new
      window.add_accel_group(accel_group)

      factory = Gtk::ItemFactory.new(Gtk::ItemFactory::TYPE_MENU_BAR, '<main>', accel_group)
      factory.create_items(items)
      return factory.get_widget('<main>')
   end

   def create_toolbar
      toolbar = Gtk::Toolbar.new

      # New button
      button = Gtk::ToolButton.new(Gtk::Stock::NEW)
      button.signal_connect('clicked') { self.new_circuit }
      button.tooltip_text = 'New circuit'
      toolbar.insert(-1, button)

      # Load button
      button = Gtk::ToolButton.new(Gtk::Stock::OPEN)
      button.signal_connect('clicked') { self.load_circuit }
      button.tooltip_text = 'Load circuit'
      toolbar.insert(-1, button)

      # Save button
      button = Gtk::ToolButton.new(Gtk::Stock::SAVE)
      button.signal_connect('clicked') { self.save_circuit }
      button.tooltip_text = 'Save circuit'
      toolbar.insert(-1, button)

      # Separator
      toolbar.insert(-1, Gtk::SeparatorToolItem.new)


      # Undo
      button = Gtk::ToolButton.new(Gtk::Stock::UNDO)
      button.signal_connect('clicked') { self.undo }
      button.tooltip_text = 'Undo'
      button.sensitive = false
      @undo_button = button
      toolbar.insert(-1, button)

      # Redo
      button = Gtk::ToolButton.new(Gtk::Stock::REDO)
      button.signal_connect('clicked') { self.redo }
      button.tooltip_text = 'Redo'
      button.sensitive = false
      @redo_button = button
      toolbar.insert(-1, button)

      # Separator
      toolbar.insert(-1, Gtk::SeparatorToolItem.new)


      # Step button
      button = Gtk::ToolButton.new(Gtk::Stock::MEDIA_FORWARD)
      button.signal_connect('clicked') do
         self.step_update
      end
      button.tooltip_text = 'Update circuit'
      @step_button = button
      toolbar.insert(-1, button)

      # Update speed spinner
      speed = Gtk::SpinButton.new(10, 10000, 1)
      speed.value = 500
      speed.tooltip_text = 'Update speed (ms)'
      @speed_button = speed

      # Run button
      running = false
      button = Gtk::ToggleToolButton.new(Gtk::Stock::MEDIA_PLAY)
      button.signal_connect('clicked') do |button|
         if running
            #button.label = "Run"
            button.stock_id = Gtk::Stock::MEDIA_PLAY
            self.stop_update
         else
            #button.label = "Stop"
            button.stock_id = Gtk::Stock::MEDIA_PAUSE
            self.run_update(speed.value)
         end
         running = !running
      end
      button.tooltip_text = 'Run circuit'
      @run_button = button
      toolbar.insert(-1, button)

      speed_item = Gtk::ToolItem.new
      speed_item.add(speed)
      toolbar.insert(-1, speed_item)

      toolbar.insert(-1, Gtk::SeparatorToolItem.new)

      @tool_buttons = {}

      # Change this to add new state buttons
      # Order: Label (String), State (Class), Tooltip text (String)
      states = [
         [TOOL_CREATE, STOCK_TOOL_CREATE, Circuits::Display::ClickState::Create,
            "Create\nLMB - Create component\nRMB - Delete component"],
         [TOOL_WIRE, STOCK_TOOL_WIRE, Circuits::Display::ClickState::Wire,
            "Wire\nLMB - Wire input to output\nRMB - Remove input wire"],
         [TOOL_EDIT, STOCK_TOOL_EDIT,   Circuits::Display::ClickState::Edit,
            "Edit\nLMB - Change properties"],
         [TOOL_UPDATE, STOCK_TOOL_UPDATE, Circuits::Display::ClickState::Update,
            "Update\nLMB - Update inputs/outputs on selected component"],
         [TOOL_MOVE, STOCK_TOOL_MOVE, Circuits::Display::ClickState::Move,
            "Update\nLMB - Pan screen"]
      ]

      buttons = []
      toggle_ids = []
      click_ids = []

      # This jumbled mess sets up the state buttons
      # All this code is to make sure only one is selected...
      states.each_with_index do |(tool, id, state, text), i|
         button = Gtk::ToggleToolButton.new(id)

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
            @display.click_state = state.new(self, @display)
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

         button.tooltip_text = text
         buttons << button

         #button_item = Gtk::ToolItem.new
         #button_item.add(button)
         toolbar.insert(-1, button)

         @tool_buttons[tool] = button
      end

      # Select first mode
      buttons[0].active = true

      sep = Gtk::SeparatorToolItem.new
      sep.draw = false
      sep.expand = true
      toolbar.insert(-1, sep)

      #button = Gtk::ToolButton.new(nil, 'load')
      #button.signal_connect('clicked') do
      #   load 'display/component_display.rb'
      #   @display.repaint
      #end
      #toolbar.insert(-1, button)

      toolbar.show_arrow = false
      #toolbar.toolbar_style = Gtk::Toolbar::Style::BOTH
      toolbar.icon_size = Gtk::IconSize::SMALL_TOOLBAR

      return toolbar
   end
end

end
