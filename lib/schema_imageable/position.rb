module SchemaImageable
  class Position
    attr_accessor :x, :y, :direction

    def initialize(x, y, direction = nil)
      @x, @y = x, y
      @direction = direction
    end

    def near_position(distance = 20)
      case direction
      when :left   then self.class.new(x - distance, y           )
      when :right  then self.class.new(x + distance, y           )
      when :top    then self.class.new(x           , y - distance)
      when :bottom then self.class.new(x           , y + distance)
      end
    end
  end
end
