require 'monitor'

# This is taken from the Ruby-GNOME2 project website
# Credit for this goes to Tal Liron

module Gtk
   GTK_PENDING_BLOCKS = []
   GTK_PENDING_BLOCKS_LOCK = Monitor.new

   def Gtk.queue &block
      if Thread.current == Thread.main
         block.call
      else
         GTK_PENDING_BLOCKS_LOCK.synchronize do
            GTK_PENDING_BLOCKS << block
         end
      end
   end

   def Gtk.main_with_queue timeout
      Gtk.timeout_add timeout do
         GTK_PENDING_BLOCKS_LOCK.synchronize do
            for block in GTK_PENDING_BLOCKS
               block.call
            end
            GTK_PENDING_BLOCKS.clear
         end
         true
      end
      Gtk.main
   end
end
