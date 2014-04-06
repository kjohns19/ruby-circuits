#!/usr/bin/env ruby

require 'gtk2'

require_relative 'component/component'

class Class
   old_init = instance_method(:initialize)
   creation_time = 1
   define_method(:initialize) do |klass|
      if klass < Circuits::Component
         puts "Hey! Class of type #{klass} created!"
      end
      k = old_init.bind(self).(klass)
      k.creation_time = creation_time
      creation_time+=1
      return k
   end
end

require_relative 'display/selector'


# Currently this creates a window with the component selector on it

window = Gtk::Window.new("Component List")
window.resizable = true
window.border_width = 4
window.signal_connect('destroy') { Gtk.main_quit }
window.set_size_request(200, 300)

Circuits::Display::Selector.new(window)

window.show_all

Gtk.main
