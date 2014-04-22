require_relative 'circuit'

module Circuits

class Serializer
   def self.save_circuit(circuit, filename)
      File.write(filename, circuit.serialize)
   end
   def self.load_circuit(filename)
      lines = []
      File.open(filename, "r") do |f|
         f.each_line { |l| lines << l }
      end
      Circuit::deserialize(lines)
   rescue Exception => e
      puts "An error occurred while loading circuit"
      puts "Error: #{e}"
      puts e.backtrace
      return nil
   end

   def self.show_open_dialog(title = "Load Circuit")
      dialog = Gtk::FileChooserDialog.new(
                     title, @window,
                     Gtk::FileChooser::ACTION_OPEN, nil,
                     [Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_CANCEL],
                     [Gtk::Stock::OPEN, Gtk::Dialog::RESPONSE_ACCEPT])
      dialog.run do |response|
         file = dialog.filename
         dialog.destroy
         if response == Gtk::Dialog::RESPONSE_ACCEPT
            return file
         else
            return nil
         end
      end
   end

   def self.show_save_dialog(title = "Save Circuit")
      dialog = Gtk::FileChooserDialog.new(
                     title, @window,
                     Gtk::FileChooser::ACTION_SAVE, nil,
                     [Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_CANCEL],
                     [Gtk::Stock::SAVE, Gtk::Dialog::RESPONSE_ACCEPT])
      done = false
      loop do
         break if done
         dialog.run do |response|
            if response == Gtk::Dialog::RESPONSE_ACCEPT
               file = dialog.filename

               if File.exists? file
                  response = Application.question("File exists. Overwrite?")
                  next unless response == Gtk::Dialog::RESPONSE_YES
               end

               dialog.destroy
               return file

            end
            dialog.destroy
            done = true
         end
      end
      nil
   end
end

end
