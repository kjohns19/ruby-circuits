require 'gtk2'

module Circuits

module Display

class ComponentArea < Gtk::DrawingArea
   def initialize
      super
      self.set_size_request(500, 500)
      self.signal_connect("expose_event") do
         alloc = self.allocation
         self.window.draw_arc(self.style.fg_gc(self.state), true, 0, 0, alloc.width, alloc.height, 0, 64*360)
      end
   end
end

end

end
