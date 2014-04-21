module Circuits

module Evaluate
   def self.eval(str)
      return nil if str.empty?

      # Arrays - just return an empty one for now
      if str =~ /^\[.*\]$/
         return []
      end

      # Escape newline and tab characters
      if str =~ /^".*"$/
         str = str[1..-2].gsub(/\\./) do |esc|
            case esc
            when "\\n"
               "\n"
            when "\\t"
               "\t"
            else
               esc[1]
            end
         end
         return str
      end

      return str[1..-2] if str =~ /^'.*'$/
      return str[1..-1].to_sym if str =~ /^:.+$/
      return Integer(str) if str =~ /^\d+$/
      return Float(str) if str =~ /^\d*\.\d+/ || str =~ /^\d+\.$/
      return true if str == 'true'
      return false if str == 'false'
      return nil
   end
end

end
