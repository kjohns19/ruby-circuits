#!/usr/bin/env ruby

require 'gtk2'

require_relative 'gtk_threads'

require_relative 'component/component'
require_relative 'display/selector'
require_relative 'display/component_area'
require_relative 'display/component_editor'
require_relative 'display/menu'
require_relative 'circuit'

window = Gtk::Window.new("Circuits")

window.resizable = true
window.border_width = 4
window.signal_connect('destroy') { Gtk.main_quit }

selector = Circuits::Display::Selector.new
editor = Circuits::Display::ComponentEditor.new

selector.select_callback do |comp|
   editor.component_class = comp
end

circuit = Circuits::Circuit.new

display = Circuits::Display::ComponentArea.new
display.circuit = circuit
display.editor = editor

menu = Circuits::Display::Menu.new(display)

displayarea = Gtk::VBox.new
displayarea.pack_start(menu, false, false)
displayarea.pack_start(display, false, false)

vpaned = Gtk::VPaned.new
vpaned.pack1(selector, true, false)
vpaned.pack2(editor, true, false)

hpaned = Gtk::HPaned.new
hpaned.pack1(vpaned, true, false)
hpaned.pack2(displayarea, true, false)

window.add(hpaned)

window.show_all

Gtk.main_with_queue 10
