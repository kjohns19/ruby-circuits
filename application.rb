module Circuits

require 'gtk2'

require_relative 'gtk_threads'

require_relative 'component/component'
require_relative 'display/selector'
require_relative 'display/component_area'
require_relative 'display/component_editor'
require_relative 'display/tool_menu'
require_relative 'circuit'

module Application
   def self.start
      @@window = Gtk::Window.new("Circuits")

      @@window.resizable = true
      @@window.border_width = 4
      @@window.signal_connect('destroy') { Gtk.main_quit }

      @@selector = Circuits::Display::Selector.new
      @@editor = Circuits::Display::ComponentEditor.new

      @@selector.select_callback do |comp|
         @@editor.component_class = comp
      end

      @@circuit = Circuits::Circuit.new

      display = Circuits::Display::ComponentArea.new
      display.circuit = @@circuit
      display.editor = @@editor

      menu = create_menu(@@window)
      toolmenu = Circuits::Display::ToolMenu.new(display)
      statusbar = Gtk::Statusbar.new

      vpaned = Gtk::VPaned.new
      vpaned.pack1(selector, true, false)
      vpaned.pack2(editor, true, false)

      hpaned = Gtk::HPaned.new
      hpaned.pack1(vpaned, true, false)
      hpaned.pack2(display, true, false)

      table = Gtk::Table.new(1, 4, false)
      table.attach(menu, 0, 1, 0, 1, Gtk::EXPAND | Gtk::FILL, 0, 0, 0)
      table.attach(toolmenu, 0, 1, 1, 2, Gtk::EXPAND | Gtk::FILL, 0, 0, 0)
      table.attach(hpaned, 0, 1, 2, 3, Gtk::EXPAND | Gtk::FILL, Gtk::EXPAND | Gtk::FILL, 0, 0)
      table.attach(statusbar, 0, 1, 3, 4, Gtk::EXPAND | Gtk::FILL, 0, 0, 0)

      @@window.add(table)

      @@window.show_all

      Gtk.main_with_queue 10
   end

   def self.exit
      Gtk.main_quit
   end

   def self.editor
      @@editor
   end
   def self.selector
      @@selector
   end

   def self.circuit
      @@circuit
   end

   def self.new_circuit
      message "New not implemented!"
   end
   def self.load_circuit
      message "Load not implemented!"
   end
   def self.save_circuit
      message "Save not implemented!"
   end

   def self.message(text)
      dialog = Gtk::MessageDialog.new(@@window,
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
   def self.create_menu(window)
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
            Gtk::Stock::QUIT, proc { self.exit }]
      ]
      accel_group = Gtk::AccelGroup.new
      window.add_accel_group(accel_group)

      factory = Gtk::ItemFactory.new(Gtk::ItemFactory::TYPE_MENU_BAR, '<main>', accel_group)
      factory.create_items(items)
      return factory.get_widget('<main>')
   end
end

end
