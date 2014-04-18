require 'gtk2'

require_relative 'gtk_threads'

require_relative 'circuit'
require_relative 'display/all_display'
require_relative 'serialize/serializer'

module Circuits

class Application
   STOCK_TOOL_CREATE = :circuit_tool_create
   STOCK_TOOL_WIRE   = :circuit_tool_wire
   STOCK_TOOL_EDIT   = :circuit_tool_edit
   STOCK_TOOL_UPDATE = :circuit_tool_update
   STOCK_TOOL_DEBUG  = :circuit_tool_debug
   STOCK_IMPORT      = :circuit_import

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
      @statusbar = Gtk::Statusbar.new

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
      table.attach(@statusbar, 0, 1, 3, 4, Gtk::EXPAND | Gtk::FILL, 0, 0, 0)

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
      @tool_buttons.each_value { |b| b.sensitive = false }
      @menu_tool_buttons.each_value { |b| b.sensitive = false }
      @run_thread = Thread.new do
         loop do
            Gtk.queue { step_update }
            sleep(speed/1000.0)
         end
      end
      @display.running = true
   end

   def stop_update
      return if @run_thread.nil?
      @run_thread.kill
      @run_thread = nil
      @run_button.stock_id = Gtk::Stock::MEDIA_PLAY
      @speed_button.sensitive = true
      @step_button.sensitive = true
      @tool_buttons.each_value { |b| b.sensitive = true }
      @menu_tool_buttons.each_value { |b| b.sensitive = true }
      @display.running = false
   end

   def toggle_update(speed)
      if @run_thread.nil?
         run_update(speed)
      else
         stop_update
      end
   end

   def undo
      message "Undo not implemented!"
   end
   def redo
      message "Undo not implemented!"
   end

   def new_circuit
      if @circuit.changed?
         response = Application.question("Unsaved changes will be lost. Continue?")
         return unless response == Gtk::Dialog::RESPONSE_YES
      end
      @circuit = Circuit.new
      @display.circuit = @circuit
      @file = nil
      change_title
   end
   def load_circuit
      if @circuit.changed?
         response = Application.question("Unsaved changes will be lost. Continue?")
         return unless response == Gtk::Dialog::RESPONSE_YES
      end
      file = Serializer.show_open_dialog
      unless file.nil?
         circuit = Serializer.load_circuit(file)
         if circuit
            @circuit = circuit
            @display.circuit = @circuit
            @file = file
            change_title
         else
            Application.message("An error occurred while loading the file",
                                Gtk::MessageDialog::ERROR)
         end
      end
   end
   def import_circuit
      file = Serializer.show_open_dialog("Import Circuit")
      unless file.nil?
         circuit = Serializer.load_circuit(file)
         if circuit
            @circuit.import(circuit)
            @display.repaint
         else
            Application.message("An error occurred while loading the file",
                                Gtk::MessageDialog::ERROR)
         end
      end
   end
   def save_circuit
      if @file.nil?
         save_circuit_as
      else
         Serializer.save_circuit(@circuit, @file)
         @circuit.changed = false
      end
   end
   def save_circuit_as
      file = Serializer.show_save_dialog
      Serializer.save_circuit(@circuit, file) unless file.nil?
      @circuit.changed = false
      @file = file
      change_title
   end

   def status=(text)
      @status_id ||= @statusbar.get_context_id("application")
      @statusbar.pop(@status_id)
      @statusbar.push(@status_id, text)
   end

   def change_title
      if @file.nil?
         str = "Untitled"
      else
         file = File::basename(@file)
         folder = File::dirname(@file)
         if folder.length > 50
            folder.reverse!
            i=0
            loop do
               n = folder.index(File::SEPARATOR, i)
               break if n.nil? || n > 50
               i = n+1
            end
            folder = folder[0,i] + "..."
            folder.reverse!
         end
         str = "#{file} (#{folder})"
      end
      @window.title = "#{str} - Circuits"
   end

   def tool=(tool)
      button = @tool_buttons[tool]
      button.active = true unless button.nil? || button.active?
      button = @menu_tool_buttons[tool]
      button.active = true unless button.nil? || button.active?
      @display.click_state = tool.new(self, @display)
   end

   def self.message(text, type = Gtk::MessageDialog::INFO, buttons = Gtk::MessageDialog::BUTTONS_CLOSE)
      dialog = Gtk::MessageDialog.new(@window,
                                      Gtk::Dialog::DESTROY_WITH_PARENT,
                                      type, buttons, text)
      response = dialog.run
      dialog.destroy
      return response
   end
   def self.question(text, buttons = Gtk::MessageDialog::BUTTONS_YES_NO)
      message(text, Gtk::MessageDialog::QUESTION, buttons)
   end

private
   def setup_stocks
      stocks = [
         [STOCK_TOOL_CREATE, '_Create', Gtk::Stock::ADD],
         [STOCK_TOOL_WIRE,   '_Wire',   Gtk::Stock::EDIT],
         [STOCK_TOOL_EDIT,   '_Edit',   Gtk::Stock::PROPERTIES],
         [STOCK_TOOL_UPDATE, '_Update', Gtk::Stock::REFRESH],
         [STOCK_TOOL_DEBUG,  '_Debug',  Gtk::Stock::INFO],
         [STOCK_IMPORT,      '_Import', Gtk::Stock::JUMP_TO]
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

      # Function to create Proc that sets the tool
      tool_proc = lambda do |tool|
         return proc do |data, widget|
            self.tool = tool if widget.active?
         end
      end
      tools = [
         Circuits::Display::ClickState::Create, Circuits::Display::ClickState::Wire,
         Circuits::Display::ClickState::Edit,   Circuits::Display::ClickState::Update,
         Circuits::Display::ClickState::Debug
      ]

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

         ['/_Tool'],
         ['/_Tool/_Create',  '<RadioItem>', nil, nil, tool_proc.call(tools[0])],
         ['/_Tool/_Wire',   '/Tool/Create', nil, nil, tool_proc.call(tools[1])],
         ['/_Tool/_Edit',   '/Tool/Create', nil, nil, tool_proc.call(tools[2])],
         ['/_Tool/_Update', '/Tool/Create', nil, nil, tool_proc.call(tools[3])],
         ['/_Tool/_Debug',  '/Tool/Create', nil, nil, tool_proc.call(tools[4])],
      ]
      accel_group = Gtk::AccelGroup.new
      window.add_accel_group(accel_group)

      factory = Gtk::ItemFactory.new(Gtk::ItemFactory::TYPE_MENU_BAR, '<main>', accel_group)
      factory.create_items(items)
      @menu_tool_buttons = {}
      factory.get_widget('/Tool').children.each_with_index do |b, i|
         @menu_tool_buttons[tools[i]] = b
      end
      return factory.get_widget('<main>')
   end

   def create_toolbar
      toolbar = Gtk::Toolbar.new

      # Update speed spinner
      speed = Gtk::SpinButton.new(10, 10000, 1)
      speed.value = 500
      speed.tooltip_text = 'Update speed (ms)'
      @speed_button = speed
      speed_item = Gtk::ToolItem.new
      speed_item.add(speed)

      buttons = [
         # New, Load, and Save
         [Gtk::Stock::NEW, proc { self.new_circuit }, 'New circuit'],
         [STOCK_IMPORT, proc { self.import_circuit }, 'Import circuit'],
         [Gtk::Stock::OPEN, proc { self.load_circuit }, 'Open circuit'],
         [Gtk::Stock::SAVE, proc { self.save_circuit }, 'Save circuit'],

         [Gtk::SeparatorToolItem.new],

         # Undo / Redo
         [Gtk::Stock::UNDO, proc { self.undo }, 'Undo', proc { |b| b.sensitive = false }],
         [Gtk::Stock::REDO, proc { self.redo }, 'Redo', proc { |b| b.sensitive = false }],

         [Gtk::SeparatorToolItem.new],

         # Step, Run, and Speed
         [Gtk::Stock::MEDIA_FORWARD, proc { self.step_update }, 'Update circuit',
               proc { |b| @step_button = b }],
         [Gtk::Stock::MEDIA_PLAY, proc { self.toggle_update(speed.value) },
               'Run circuit', proc { |b| @run_button = b }],
         [speed_item],

         [Gtk::SeparatorToolItem.new],
      ]

      buttons.each do |(stock, func, tooltip, block)|
         if func.nil?
            toolbar.insert(-1, stock)
         else
            button = Gtk::ToolButton.new(stock)
            button.signal_connect('clicked', &func)
            button.tooltip_text = tooltip
            block.call(button) if block
            toolbar.insert(-1, button)
         end
      end

      @tool_buttons = {}

      # Change this to add new state buttons
      # Order: Label (String), State (Class), Tooltip text (String)
      states = [
         [STOCK_TOOL_CREATE, Circuits::Display::ClickState::Create,
            "Create\nLMB - Create component\nRMB - Delete component"],
         [STOCK_TOOL_WIRE, Circuits::Display::ClickState::Wire,
            "Wire\nLMB - Wire input to output\nRMB - Remove input wire"],
         [STOCK_TOOL_EDIT,   Circuits::Display::ClickState::Edit,
            "Edit\nLMB - Change properties"],
         [STOCK_TOOL_UPDATE, Circuits::Display::ClickState::Update,
            "Update\nLMB - Update inputs/outputs on selected component"],
         [STOCK_TOOL_DEBUG, Circuits::Display::ClickState::Debug,
            "Debug\nLMB - Toggle showing inputs/outputs"]
      ]

      buttons = []
      toggle_ids = []
      click_ids = []

      states.each_with_index do |(id, state, text), i|
         button = Gtk::RadioToolButton.new(buttons[0], id)

         button.signal_connect('toggled') do |button|
            self.tool = state if button.active?
         end
         button.tooltip_text = text
         buttons << button

         toolbar.insert(-1, button)
         @tool_buttons[state] = button
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
