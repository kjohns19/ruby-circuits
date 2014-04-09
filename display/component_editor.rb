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
      @getters.each do |getter|
         getter[1].set(@instance, getter[0].call)
      end
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

      label = Gtk::Label.new(property.label)
      label.xalign = 0

      widget, getter, setter = create_widget(type, values)

      val = property.get(@instance)
      puts "Setting value to #{val.inspect}"
      setter.call(val)

      return [label, widget], [getter, property]
   end
   
   def create_widget(type, values)
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
      elsif type <= Array
         count = values.length
         widget = []
         gs = []
         ss = []
         values.each_with_index do |value, i|
            w, g, s = create_widget(value[0], value[1])
            widget << [Gtk::Label.new("#{i+1}:"), w]
            gs << g
            ss << s
         end
         getter = lambda { gs.map { |g| g.call } }
         setter = lambda do |values|
            values.each_with_index { |v, i| ss[i].call(v) }
         end
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
end

end

end
