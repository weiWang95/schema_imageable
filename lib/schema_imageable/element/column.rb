require_relative "table"

module SchemaImageable
  module Element
    class Column
      FONT_SIZE = 16
      MIN_SPACE = 30
      MARGIN = 10
      MAX_TYPE_WIDTH = FONT_SIZE * 5
      DEFAULT_HEIGHT = 30
      TEXT_BEGIN_HEIGHT = (DEFAULT_HEIGHT + FONT_SIZE) / 2

      attr_reader :table
      attr_reader :name, :type, :options

      def initialize(table, type, name, **options)
        @table   = table
        @name    = name
        @type    = type
        @options = options
      end

      def draw(image, x = 0, y = 0)
        paint = SchemaImageable::Draw.new

        paint.text(x + MARGIN, y + TEXT_BEGIN_HEIGHT, name)  # column name
        paint.text(x + table.width - MAX_TYPE_WIDTH - MARGIN, y + TEXT_BEGIN_HEIGHT, type) # column type

        paint.line(x + MARGIN, y + DEFAULT_HEIGHT, x + table.width - MARGIN, y + DEFAULT_HEIGHT) # bottom line

        paint.draw(image)
      end

      def min_width
        @min_width ||= (name.size / 2) * FONT_SIZE + MIN_SPACE + MAX_TYPE_WIDTH + MARGIN * 2
      end
    end
  end
end

