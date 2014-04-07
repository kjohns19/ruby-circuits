#!/usr/bin/env ruby

require 'gtk2'

require_relative 'component/component'

class Class
   old_init = instance_method(:initialize)
   creation_time = 1
   define_method(:initialize) do |klass|
      k = old_init.bind(self).(klass)
      if klass < Circuits::Component
         puts "Hey! Class of type #{klass} created!"
         k.creation_time = creation_time
         creation_time+=1
      end
      return k
   end
end

require_relative 'display/selector'
require_relative 'display/component_area'
require_relative 'display/component_editor'


# Currently this creates a window with the component selector on it

window = Gtk::Window.new("Component List")

window.resizable = true
window.border_width = 4
window.signal_connect('destroy') { Gtk.main_quit }

selector = Circuits::Display::Selector.new
editor = Circuits::Display::ComponentEditor.new

selector.select_callback do |comp|
   editor.set_component_class(comp)
end

display = Circuits::Display::ComponentArea.new


vpaned = Gtk::VPaned.new
vpaned.pack1(selector, true, false)
vpaned.pack2(editor, true, false)

hpaned = Gtk::HPaned.new
hpaned.pack1(vpaned, true, false)
hpaned.pack2(display, true, false)

window.add(hpaned)

window.show_all

Gtk.main
