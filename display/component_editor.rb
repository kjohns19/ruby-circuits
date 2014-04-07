require 'gtk2'

module Circuits

module Display

class ComponentEditor < Gtk::ScrolledWindow
   def initialize
      super
      self.set_size_request(200, -1)
      self.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_AUTOMATIC)

      @table = Gtk::Table.new(1, 2, true)

      @title = Gtk::Label.new("Select A Component")
      @widgets = []
      @instances = Hash.new { |hash, key| hash[key] = key.new(nil) if key }

      @table.attach(@title, 0, 2, 0, 1)

      h_adjust = Gtk::Adjustment.new(0, 0, 100, 1, 1, 200)
      v_adjust = Gtk::Adjustment.new(0, 0, 100, 1, 1, 300)

      viewport = Gtk::Viewport.new(h_adjust, v_adjust)
      viewport.add(@table)

      self.add(viewport)
   end

   def set_component_class(component)
      return if @component == component || component.nil?

      properties = component.properties

      @widgets.each do |ws|
         @table.remove(ws[0])
         @table.remove(ws[1])
      end
      @widgets = []

      @table.resize(1+properties.length, 2)

      properties.each_with_index do |p, i|
         add_property(p, i+1)
      end

      @component = component

      self.show_all
   end

   def add_property(property, index)
      puts "Adding property #{property}"

      label = Gtk::Label.new(property.label)
      entry = get_widget(property)

      @table.attach(label, 0, 1, index, index+1)
      @table.attach(entry, 1, 2, index, index+1)

      @widgets << [label, entry]
   end

   def get_widget(property)
      widget = nil

      type = property.type
      values = property.values

      puts "Property: #{type} - #{values}"

      if type == String
         widget = Gtk::Entry.new
         widget.define_singleton_method(:value) { self.text }
         widget.define_singleton_method(:value=) { |v| self.text=v }
      elsif type == Fixnum
         widget = Gtk::SpinButton.new(values.begin, values.end, 1)
      elsif type == TrueClass
         widget = Gtk::CheckButton.new
         widget.define_singleton_method(:value) { self.active? }
         widget.define_singleton_method(:value=) { |val| self.active = val }
      else
         widget = Gtk::Label.new("Bad!")
      end

      return widget
   end

=begin
   def set_component_class(component)
      return if @component == component || component.nil?

      old = @instances[@component]
      if old
         @widgets.each do |w|
            property = w[1]
            value = w[0].value
            puts "Calling setter for #{property}"
            property.set(old, value)
         end
      end

      @title.text = component.name
      @widgets.each { |w| @box.remove(w[0]) }
      @widgets = []
      @component = component
      new = @instances[@component]

      component.properties.each do |property|
         widget = property_widget(property)

         widget.value = property.get(new)

         @box.pack_start(widget)

         @widgets << [widget, property]
      end

      self.show_all
   end
=end

   def create_component(circuit)
      comp = @component.new(circuit)

      @widgets.each do |arr|
         widget = arr[0]
         property = arr[1]
         property.set(comp, widget.value)
      end
   end

private
   def property_widget(property)
      setString = lambda do |val|
         if val.nil?
            return ""
         elsif val.is_a? String
            return "\"#{val}\""
         else
            return val.to_s
         end
      end
      widget = nil
      puts property.type
      puts "Hi! #{property}"
      if property.type == Array
         widget = Gtk::VBox.new
         widget.pack_start(Gtk::Label.new(property.label))


         value_widgets = []
         property.values.times do |i|
            puts "Hey #{i}!"
            box = Gtk::HBox.new
            box.pack_start(Gtk::Label.new("#{i+1}:"))
            entry = Gtk::Entry.new

            box.pack_start(entry)
            widget.pack_start(box)

            value_widgets << entry
         end

         widget.define_singleton_method(:value) do
            values = Array.new(property.values)
            value_widgets.each_with_index do |val, i|
               str = val.text.strip
               next if str.empty?

               match = str.match /^"(?<string>.*)"$/
               if match
                  values[i] = match[:string]
                  next
               end
               match = str.match /^[-+]?[0-9]+$/
               if match
                  values[i] = Integer(str)
                  next
               end
               values[i] = Float(str) rescue nil
            end
            puts "Hey there! Values are #{values.inspect}"
            return values
         end
         widget.define_singleton_method(:value=) do |val|
            puts "Hello! Values are #{val.inspect}"
            value_widgets.each_with_index do |v, i|
               v.text = setString.call(val[i])
            end
         end
      else
         widget = Gtk::HBox.new

         widget.pack_start(Gtk::Label.new("#{property.label}:"))

         values = property.values
         entry = nil
         if values.is_a? Range
            entry = Gtk::SpinButton.new(values.begin, values.end, 1)
            widget.define_singleton_method(:value) { entry.value }
            widget.define_singleton_method(:value=) { |val| entry.value = val }
         else
            entry = Gtk::Entry.new
            widget.define_singleton_method(:value) { entry.text }
            widget.define_singleton_method(:value=) do |val|
               entry.text = setString.call(val)
            end
         end
         widget.pack_start(entry)
      end
      return widget
   end

end

end

end
