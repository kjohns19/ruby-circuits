require 'gtk2'

require_relative '../gtk_threads'
require_relative 'menu'
require_relative 'toolbar'
require_relative 'editor'
require_relative 'selector'

require_relative '../circuit'
require_relative '../display/all_display'
require_relative '../serialize/serializer'

module Circuits

module Gui

class Application
   STOCK_TOOL_CREATE = :circuit_tool_create
   STOCK_TOOL_WIRE   = :circuit_tool_wire
   STOCK_TOOL_EDIT   = :circuit_tool_edit
   STOCK_TOOL_UPDATE = :circuit_tool_update
   STOCK_TOOL_DEBUG  = :circuit_tool_debug
   STOCK_IMPORT      = :circuit_import

   attr_reader :editor, :selector, :display

   def initialize
      setup_stocks
      
      # Set up window
      @window = Gtk::Window.new("Circuits")
      @window.resizable = true
      @window.border_width = 4
      @window.signal_connect('delete_event') do
         if @circuit.changed?
            response = Application.question("Really quit? Unsaved changes will be lost")
            next true unless response == Gtk::Dialog::RESPONSE_YES
         end
         false
      end
      @window.signal_connect('destroy') { Gtk.main_quit }

      @selector = Selector.new(self)
      @editor = Editor.new(self)

      @selector.select_callback do |comp|
         @editor.component_class = comp
      end

      @circuit = Circuits::Circuit.new

      @display = Circuits::Display::ComponentArea.new(self)
      @display.circuit = @circuit

      @menu = Menu.new(self)
      menu = @menu.create(@window)
      @toolbar = Toolbar.new(self)
      @statusbar = Gtk::Statusbar.new

      vpaned = Gtk::VPaned.new
      vpaned.pack1(@selector, true, false)
      vpaned.pack2(@editor, false, false)

      hpaned = Gtk::HPaned.new
      hpaned.pack1(vpaned, false, false)
      hpaned.pack2(@display, true, false)

      table = Gtk::Table.new(1, 4, false)
      table.attach(menu,       0, 1, 0, 1, Gtk::EXPAND | Gtk::FILL, 0, 0, 0)
      table.attach(@toolbar,   0, 1, 1, 2, Gtk::EXPAND | Gtk::FILL, 0, 0, 0)
      table.attach(hpaned,     0, 1, 2, 3, Gtk::EXPAND | Gtk::FILL, Gtk::EXPAND | Gtk::FILL, 0, 0)
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
      @toolbar.run_button.stock_id = Gtk::Stock::MEDIA_PAUSE
      @toolbar.speed_button.sensitive = false
      @toolbar.step_button.sensitive = false
      @toolbar.tool_buttons.each_value { |b| b.sensitive = false }
      @menu.tool_buttons.each_value { |b| b.sensitive = false }
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
      @toolbar.run_button.stock_id = Gtk::Stock::MEDIA_PLAY
      @toolbar.speed_button.sensitive = true
      @toolbar.step_button.sensitive = true
      @toolbar.tool_buttons.each_value { |b| b.sensitive = true }
      @menu.tool_buttons.each_value { |b| b.sensitive = true }
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
            @display.position = @circuit.center
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
            @circuit.import(circuit, @display.position)
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
      button = @toolbar.tool_buttons[tool]
      button.active = true unless button.nil? || button.active?
      button = @menu.tool_buttons[tool]
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

end

end

end
