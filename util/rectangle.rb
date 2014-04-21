module Circuits

class Rectangle
   attr_accessor :x, :y, :width, :height
   def initialize(x, y, width, height)
      width = -width if width < 0
      height = -height if height < 0
      @x, @y, @width, @height = x, y, width, height
   end


   def contains?(x, y)
      x.between?(left, right) && y.between?(top, bottom)
   end

   def left
      @x
   end
   def left=(value)
      return left if value > top
      @width+=@x-value
      @x = value
   end

   def top
      @y
   end
   def top=(value)
      return top if value > bottom
      @height+=@y-value
      @y = value
   end

   def right
      @x+@width
   end
   def right=(value)
      return right if value < left
      @width = value-@x
      right
   end
   def bottom
      @y+@height
   end
   def bottom=(value)
      return bottom if value < top
      @height = value-@y
      bottom
   end

   def center
      [x+width/2.0, y+height/2.0]
   end

   # Corners
   def top_left
      [left, top]
   end
   def top_right
      [right, top]
   end
   def bottom_left
      [left, bottom]
   end
   def bottom_right
      [right, bottom]
   end

   def union(*args)
      case args.length
      when 1
         return union_rect(*args[0].to_a)
      when 4
         return union_rect(*args)
      else
         raise ArgumentError, "wrong number of arguments (#{args.length}). Expects 1 or 4."
      end
   end


   def intersects?(*args)
      case args.length
      when 1
         return intersects_rect?(*args[0].to_a)
      when 4
         return intersects_rect?(*args)
      else
         raise ArgumentError, "wrong number of arguments (#{args.length}). Expects 1 or 4."
      end
   end

   def to_a
      [x, y, width, height]
   end

private
   def union_rect(x, y, width, height)
      newx = [x, self.x].min
      newy = [y, self.y].min
      neww = [x+width, self.right].max - newx
      newh = [y+height, self.bottom].max - newy
      Rectangle.new(newx, newy, neww, newh)
   end
   def intersects_rect?(x, y, width, height)
      (left.between?(x, x+width) || right.between?(x, x+width)) &&
      (top.between?(y, y+height) || bottom.between?(y, y+height))
   end
end

end
