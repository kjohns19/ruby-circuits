require 'gtk2'

module Circuits

module Display

class ComponentEditor < Gtk::ScrolledWindow
   def initialize
      super
      self.set_size_request(200, 400)
      self.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_AUTOMATIC)

      @box = Gtk::VBox.new

      @title = Gtk::Label.new("Select A Component")
      @widgets = []
      @instances = Hash.new { |hash, key| hash[key] = key.new(nil) if key }

      @box.pack_start(@title)

      self.add(@box)
   end

   def set_component_class(component)
      return if @component == component || component.nil?

      old = @instances[@component]
      if old
         @widgets.each do |w|
            property = w[1]
            value = w[0].value
            property.set(old, value)
         end
      end

      @title.text = component.name
      @widgets.each { |w| @box.remove(w[0]) }
      @widgets = []
      @component = component
      new = @instances[@component]

      component.properties.each do |property|
         widget = ComponentEditor.property_widget(property)

         widget.value = property.get(new)

         @box.pack_start(widget)

         @widgets << [widget, property]
      end

      self.show_all
   end

   def create_component(circuit)
      comp = @component.new(circuit)

      @widgets.each do |arr|
         widget = arr[0]
         property = arr[1]
         property.set(comp, widget.value)
      end
   end

   def self.property_widget(property)
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
