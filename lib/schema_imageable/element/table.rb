require_relative "column"
require_relative "../draw"

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

      attr_reader :name, :options, :columns
      attr_accessor :point

      def initialize(name, **options)
        @name    = name
        @options = options
        @columns = []
      end

      def add_column(type, name, **options)
        return if type == "index"
        columns << Column.new(self, type, name, options)
      end

      def draw(image, x = 0, y = 0)
        paint = SchemaImageable::Draw.new(fill: "white")
        paint.roundrectangle(x, y, width, HEAD_HEIGHT + columns.size * Column::DEFAULT_HEIGHT)  # table border
        paint.line(x, y + HEAD_HEIGHT, x + width, y + HEAD_HEIGHT)  # table name border
        paint.draw(image)

        paint = SchemaImageable::Draw.new(pointsize: FONT_SIZE)
        paint.text(x + calculate_text_begin_x(width, name.size / 2, FONT_SIZE), y + TEXT_BEGIN_HEIGHT, name) # table name
        paint.draw(image)

        draw_columns(image, x, y + HEAD_HEIGHT)
      end

      def draw_columns(image, x, y)
        columns.each_with_index do |column, index|
          column.draw(image, x, y + index * Column::DEFAULT_HEIGHT)
        end
      end

      def width
        @width ||= columns.max { |c1, c2| c1.min_width <=> c2.min_width }.min_width
      end

      def height
        @height ||= HEAD_HEIGHT + Column::DEFAULT_HEIGHT * columns.size
      end

      private
        def calculate_text_begin_x(width, text_size, font_size)
          (width - text_size * font_size) / 2
        end
    end
  end
end
