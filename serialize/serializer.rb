module Circuits

class Serializer
   def self.save_circuit(circuit, filename)
      File.write(filename, serialize_circuit(circuit))
   end
   def self.load_circuit(filename)
      lines = []
      File.open(filename, "r") do |f|
         f.each_line { |l| lines << l }
      end
      deserialize_circuit(lines)
   rescue
      nil
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
private
   def self.serialize_circuit(circuit)
      str = ""
      circuit.components.each do |comp|
         str+=self.serialize_component(comp)
      end
      circuit.wires.each do |wire|
         str+=self.serialize_wire(wire)
      end
      circuit.updates.each do |delay, set|
         str+="update #{delay}"
         set.sort { |a,b| a.id <=> b.id }.each do |comp|
            str+=" #{comp.id}"
         end
         str+="\n"
      end
      return str
   end

   def self.serialize_component(comp)
      str = "component #{comp.class.name}\n"
      str+= "   position= #{comp.position.inspect}\n"
      comp.class.properties.each do |property|
         str+= "   #{property.setter} #{property.get(comp).inspect}\n"
      end

      comp.inputs_current.each_with_index do |input, i|
         str+= "   in #{i} #{input.inspect}\n"
      end

      comp.outputs.each_with_index do |output, i|
         str+= "   out #{i} #{output.inspect}\n"
      end

      str+="end\n"
      return str
   rescue Exception => e
      puts "An error occurred while serializing component"
      puts "Error: #{e}"
      puts e.backtrace
      return "COMPONENT ERROR HERE\n"
   end

   def self.serialize_wire(wire)
      str = "wire #{wire.comp_in.id}:#{wire.input} #{wire.comp_out.id}:#{wire.output}"

      wire.points[1..-2].each do |(x, y)|
         str+= " (#{x} #{y})"
      end
      str+="\n"
      return str
   rescue Exception => e
      puts "An error occurred while serializing wire"
      puts "Error: #{e}"
      puts e.backtrace
      puts "Wire: #{wire}"
      puts "#{wire.comp_in.inspect}:#{wire.input} #{wire.comp_out.inspect}:#{wire.output}"
      puts "Points: #{wire.points}"
      return "WIRE ERROR HERE\n"
   end

   def self.deserialize_circuit(lines)
      circuit = Circuit.new

      line_num = 0
      loop do
         break if line_num >= lines.length
         line = lines[line_num]

         next if line.strip.empty?

         case line
         when /^component/
            component, read = deserialize_component(lines[line_num..-1], circuit)
         when /^wire/
            wire = deserialize_wire(line, circuit)
            read = 1
         when /^update/
            split = line.split
            delay = split[1].to_i
            split[2..-1].each do |i|
               circuit.update_next(circuit.components[i.to_i], delay)
            end
            read = 1
         else
            puts "Error: Invalid line \"#{line}\""
            return nil
         end
         line_num+=read unless read.nil?
      end

      circuit.components.each { |c| c.active = true }
      circuit.changed = false

      return circuit
   end

   def self.deserialize_component(lines, circuit)
      match = lines[0].match /^\s*component\s+(?<class>.*)$/
      return nil, 1 if match.nil?

      klass = match[:class].split("::").inject(::Object) { |o, c| o.const_get c }

      comp = klass.new(circuit) do |comp|
         comp.active = false
      end

      read = 1
      ended = false

      lines[1..-1].each do |line|
         break if ended
         case line
         when /\s*end\s*$/
            ended = true
         when /^\s*(in|out)\s+(\d+)\s+(.*)\s*$/
            func = ($1 == 'in') ? :inputs_current : :outputs
            index = $2.to_i
            value = eval($3)
            comp.send(func)[index] = value
         when /^\s*([^\s]+)\s+(.*)\s*$/
            setter = $1.to_sym
            value = eval($2)
            comp.send(setter, value)
         else
            puts "Error: Invalid line while reading component \"#{line}\""
         end
         read+=1
      end
      unless ended
         puts "Expected end while reading component"
      end
      return comp, read
   rescue Exception => e
      puts "An error occurred while deserializing component"
      puts "Error: #{e}"
      puts e.backtrace
      return nil, 1
   end

   def self.deserialize_wire(line, circuit)
      match = line.match(
         /^\s*wire (?<in_id>\d+):(?<in>\d+)\s+(?<out_id>\d+):(?<out>\d+)(?:\s+(?<points>.*))?$/)
      return nil if match.nil?

      comp_in = circuit.components[match[:in_id].to_i]
      comp_out = circuit.components[match[:out_id].to_i]

      wire = Circuits::Wire.new(comp_in, match[:in].to_i)

      match[:points].scan(/\((-?\d+)\s+(-?\d+)\)/).each do |x, y|
         x = x.to_i
         y = y.to_i
         wire.add([x, y])
      end

      wire.connect(comp_out, match[:out].to_i)
      return wire
   rescue Exception => e
      puts "An error occurred while deserializing wire"
      puts "Error: #{e}"
      puts e.backtrace
      return nil, 1
   end
end

end
