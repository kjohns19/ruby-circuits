require_relative 'component'

# Main module for all circuit classes
module Circuits

# Module for output components
module Output

# Nothing here yet!
Display = Component.create do
   MAX_LINES = 8
   MAX_WIDTH = 20
   
   def initialize(circuit, &block)
      @lines = []
      super(4, 0, circuit, &block)
   end

   def input_label(input)
      case input
      when 0
         'clk'
      when 1
         'write'
      when 2
         'data'
      when 3
         'clear'
      end
   end

   def write(text)
      text.split("\n").each do |split|
         split.gsub("\t", "   ").scan(/.{1,#{MAX_WIDTH}}/) do |line|
            @lines << line
         end
      end
      @lines = @lines.last(MAX_LINES) if @lines.length > MAX_LINES
   end

   def update_outputs
      if inputs_current[1] && inputs_current[0] && !inputs_old[0]
         if inputs_current[3]
            @lines = []
         else
            write(inputs_current[2].to_s)
         end
      end
   end

   def size
      [8, 6]
   end

   def draw(cr)
      super
      cr.set_source_rgb(0, 0, 0)
      cr.rounded_rectangle(1.65, 0.85, 6.2, 4.3, 0.12)
      cr.stroke

      cr.select_font_face('Courier New', 'normal', 'bold')
      @lines.reverse.each_with_index do |line, i|
         cr.move_to(1.75, 4.9-0.50*i)
         cr.show_text(line)
      end
      #cr.move_to(2, 2)
      #cr.show_text("Hello world!")
   end
end

end

end
