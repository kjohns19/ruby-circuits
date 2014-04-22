require 'gtk2'
require_relative '../display/click_state'

module Circuits

module Gui

class Menu
   attr_reader :tool_buttons
   def initialize(app)
      @app = app
   end

   def create(window)
      # Function to create Proc that sets the tool
      tool_proc = lambda do |tool|
         return proc do |data, widget|
            @app.tool = tool if widget.active?
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
            Gtk::Stock::NEW, proc { @app.new_circuit }],
         ['/_File/_Load', '<StockItem>', '<control>O',
            Gtk::Stock::OPEN, proc { @app.load_circuit }],
         ['/_File/_Save', '<StockItem>', '<control>S',
            Gtk::Stock::SAVE, proc { @app.save_circuit }],
         ['/_File/Save _As', '<StockItem>', '<shift><control>S',
            Gtk::Stock::SAVE_AS, proc { @app.save_circuit_as }],
         ['/_File/sep', '<Separator>', nil, nil, nil],
         ['/_File/_Quit', '<StockItem>', '<control>Q',
            Gtk::Stock::QUIT, proc { @app.exit }],

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
      @tool_buttons = {}
      factory.get_widget('/Tool').children.each_with_index do |b, i|
         @tool_buttons[tools[i]] = b
      end
      return factory.get_widget('<main>')
   end
end

end

end
