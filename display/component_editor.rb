require 'gtk2'

module Circuits

module Display

class ComponentEditor < Gtk::ScrolledWindow
   def initialize
      super
      self.set_size_request(200, -1)
      self.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_AUTOMATIC)

      @title = Gtk::Label.new("Select A Component")
      @getters = []
      @instances = Hash.new { |hash, key| hash[key] = key.new(nil) if key }


      h_adjust = Gtk::Adjustment.new(0, 0, 400, 1, 1, 200)
      v_adjust = Gtk::Adjustment.new(0, 0, 400, 1, 1, 300)

      @viewport = Gtk::Viewport.new(h_adjust, v_adjust)

      reset_table

      self.add(@viewport)
   end

   def set_component_class(component)
      return if @component == component || component.nil?

      #Save values of properties
      call_setters
      @getters = []

      #Get current instance
      @instance = @instances[component]

      properties = component.properties

      #Remove old widgets from the table
      reset_table

      @table.resize(1+properties.length, 2)

      #Add widgets for each property
      i = 1
      properties.each do |p|
         @table.set_row_spacing(i-1, 20)
         i = add_property(p, i)
      end

      @component = component

      @title.text = component.name

      self.show_all
   end

   def create_component(circuit)
      return nil if @component.nil?
      comp = @component.new(circuit)

      @getters.each do |arr|
         getter = arr[0]
         property = arr[1]
         property.set(comp, getter.call)
      end

      return comp
   end

private

   def call_setters
      #Save values of properties
      @getters.each do |getter|
         puts "Getter is #{getter[0]}"
         getter[1].set(@instance, getter[0].call) unless getter[0].nil?
      end
   end

   def add_property(property, index)
      puts "Adding property #{property}"

      add_widgets = lambda do |ws, i|
         ws[0].width_request = 64
         ws[1].width_request = 100
         @table.attach(ws[0], 0, 1, i, i+1, Gtk::FILL, Gtk::FILL)
         @table.attach(ws[1], 1, 2, i, i+1, Gtk::FILL, Gtk::FILL)
      end

      widgets, getters = get_widgets(property)

      next_index = index + 1
      
      if widgets[1].is_a? Array
         @table.attach(widgets[0], 0, 2, index, index+1, Gtk::FILL, Gtk::FILL)
         widgets[1].each_with_index { |ws, i| add_widgets.call(ws, index+1+i) }
         next_index = index + widgets[1].length
      else
         add_widgets.call(widgets, index)
      end
      @getters << getters
      return next_index
   end

   def get_widgets(property)
      widgets = []

      type = property.type
      values = property.values

      label = Gtk::Label.new("#{property.label}:")
      label.xalign = 0

      widget, getter, setter = create_widget(property, type, values)

      val = property.get(@instance)
      puts "Setting value to #{val.inspect}"
      setter.call(val) unless setter.nil?

      return [label, widget], [getter, property]
   end
   
   def create_widget(property, type, values)
      if type == nil
         #Allow string, number, or symbol
         widget = Gtk::Entry.new
         widget.xalign = 0
         getter = lambda do
            str = widget.text.strip
            return nil if str.empty?
            return str[1..-2] if str =~ /^".*"$/
            return str[1..-1].to_sym if str =~ /^:.+$/
            return Integer(str) if str =~ /^\d+$/
            return Float(str) if str =~ /^\d*\.\d+/ || str =~ /^\d+\.$/
            return nil
         end
         setter = lambda do |val|
            if val.nil?
               str = ""
            else
               str = val.is_a?(String) ? "\"#{val}\"" :
                     val.is_a?(Symbol) ? ":#{val}" :
                     val.to_s
            end
            widget.text = str
         end
      elsif type <= Integer || type <= Float
         widget = Gtk::SpinButton.new(*values)
         widget.xalign = 0
         getter = lambda do
            val = widget.value
            return val if type == Float
            return Integer(val)
         end
         setter = widget.method(:value=)
      elsif type == TrueClass
         widget = Gtk::CheckButton.new
         getter = widget.method(:active?)
         setter = widget.method(:active=)
      elsif type == String || type == Symbol
         widget = Gtk::Entry.new
         widget.xalign = 0
         getter = lambda { type == String ? widget.text : widget.text_to_sym }
         setter = lambda { |val| widget.text = val.to_s }
      elsif type <= Array && property
         widget = Gtk::Button.new("click to set")
         
         widget.signal_connect('clicked') do
            show_array_setter(property)
         end

         getter = nil
         setter = nil
      else
         widget = Gtk::Label.new("Invalid")
         getter = lambda { nil }
         setter = lambda { |val| }
      end

      return widget, getter, setter
   end

   def reset_table
      @table.remove(@title) if @table
      @viewport.remove(@table) if @table

      @table = Gtk::Table.new(1, 2)
      @table.row_spacings = 4
      @table.column_spacings = 4

      @table.attach(@title, 0, 2, 0, 1, Gtk::FILL, Gtk::FILL)
      @viewport.add(@table)
   end

   def show_array_setter(property)
      call_setters

      values = property.values

      count = values[2]
      count = @instance.send(count) if count.is_a? Symbol

      widgets = []
      getters = []

      current = property.get(@instance)

      count.times do |i|
         w, g, s = create_widget(nil, values[0], values[1])
         l = Gtk::Label.new("#{i+1}:")
         l.width_request = 50
         w.width_request = 100
         widgets << [l, w]
         getters << g
         s.call(current[i])
      end

      getter = lambda { gs.map { |g| g.call } }

      table = Gtk::Table.new(count, 2)
      widgets.each_with_index do |w, i|
         table.attach(w[0], 0, 1, i+1, i+2, Gtk::FILL, Gtk::FILL)
         table.attach(w[1], 1, 2, i+1, i+2, Gtk::FILL, Gtk::FILL)
      end

      h_adjust = Gtk::Adjustment.new(0, 0, 400, 1, 1, 200)
      v_adjust = Gtk::Adjustment.new(0, 0, 400, 1, 1, 300)
      viewport = Gtk::Viewport.new(h_adjust, v_adjust)
      viewport.add(table)

      scroll = Gtk::ScrolledWindow.new
      scroll.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_AUTOMATIC)
      scroll.set_size_request(200, 200)
      scroll.add(viewport)

      dialog = Gtk::Dialog.new(
                  property.label, $main_application_window,
                  Gtk::Dialog::MODAL | Gtk::Dialog::DESTROY_WITH_PARENT,
                  [Gtk::Stock::OK, Gtk::Dialog::RESPONSE_ACCEPT],
                  [Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_REJECT])
      dialog.signal_connect('response') do |dialog, id|
         puts "ID of #{id}"
         if id == Gtk::Dialog::RESPONSE_ACCEPT
            property.set(@instance, getters.map { |g| g.call })
         end
         dialog.destroy
      end

      dialog.vbox.add(scroll)
      dialog.show_all
   end
end

end

end
