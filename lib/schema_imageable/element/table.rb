require_relative "column"
require_relative "../draw"
require_relative "../position"

module SchemaImageable
  module Element
    class Table
      module DSL
        %i[string text integer bigint float decimal datetime timestamp time date binary boolean index].each do |type|
          define_method(type) do |name, **options|
            add_column(type.to_s, name, options)
          end
        end
      end
      include DSL

      HEAD_HEIGHT = 40
      FONT_SIZE = 24
      TEXT_BEGIN_HEIGHT = (HEAD_HEIGHT + FONT_SIZE) / 2
      HEAD_MARGIN = 30
      BOTTOM_PADDING = 20
      REFERENCE_PORT_MOVE_DISTANCE = 20

      attr_reader :name, :options, :columns
      attr_accessor :position, :reference_ports

      def initialize(name, **options)
        @name    = name
        @options = options
        @columns = []
        @reference_ports = { left: [], right: [], top: [], bottom: [] }
      end

      def add_column(type, name, **options)
        return if type == "index"
        columns << Column.new(self, type, name, options)
      end

      def draw(image)
        paint = SchemaImageable::Draw.new(fill: "white")
        paint.roundrectangle(position.x, position.y, width, height)  # table border
        paint.line(position.x, position.y + HEAD_HEIGHT, position.x + width, position.y + HEAD_HEIGHT)  # table name bottom border
        paint.draw(image)

        paint = SchemaImageable::Draw.new(pointsize: FONT_SIZE)
        paint.text(position.x + name_position_x, position.y + TEXT_BEGIN_HEIGHT, name) # table name
        paint.draw(image)

        draw_columns(image, position.x, position.y + HEAD_HEIGHT)
      end

      def draw_columns(image, x, y)
        columns.each_with_index do |column, index|
          column.draw(image, x, y + index * Column::DEFAULT_HEIGHT)
        end
      end

      def width
        @width ||= begin
          max_column_width = columns.max { |c1, c2| c1.min_width <=> c2.min_width }.min_width
          max_column_width > head_width ? max_column_width : head_width
        end
      end

      def height
        @height ||= HEAD_HEIGHT + Column::DEFAULT_HEIGHT * columns.size + BOTTOM_PADDING
      end

      def head_width
        @head_width ||= (name.size / 2) * FONT_SIZE + 2 * HEAD_MARGIN
      end

      def name_position_x
        (width - (name.size / 2) * FONT_SIZE) / 2
      end

      def center_position
        @center        ||= SchemaImageable::Position.new(position.x + width / 2, position.y + height / 2)
      end

      def left_center_position
        @left_center   ||= SchemaImageable::Position.new(position.x            , position.y + height / 2, :left  )
      end

      def right_center_position
        @right_center  ||= SchemaImageable::Position.new(position.x + width    , position.y + height / 2, :right )
      end

      def top_center_position
        @top_center    ||= SchemaImageable::Position.new(position.x + width / 2, position.y             , :top   )
      end

      def bottom_center_position
        @bottom_center ||= SchemaImageable::Position.new(position.x + width / 2, position.y + height    , :bottom)
      end

      def include_position?(pos)
        pos.x >= position.x - 15 && pos.x <= position.x + width + 15 &&
          pos.y >= position.y - 15 && pos.y <= position.y + height + 15
      end

      def add_reference_port(direction)
        port = calculate_new_reference_port_position(direction)
        reference_ports[direction] << port
        port
      end

      def calculate_new_reference_port_position(direction)
        count = reference_ports[direction].size
        operator = count.odd? ? :- : :+
        move_times = count.odd? ? count / 2 + 1 : count / 2
        distance = move_times * REFERENCE_PORT_MOVE_DISTANCE

        start_position = instance_variable_get("@#{direction}_center")

        case direction
        when :left, :right then SchemaImageable::Position.new(start_position.x, start_position.y.send(operator, distance), direction)
        when :top, :bottom then SchemaImageable::Position.new(start_position.x.send(operator, distance), start_position.y, direction)
        else raise ArgumentError
        end
      end
    end
  end
end
