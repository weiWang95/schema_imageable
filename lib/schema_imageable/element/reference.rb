require "byebug"
require_relative "../path_finder"

module SchemaImageable
  module Element
    class Reference
      LINE_WIDTH = 4

      attr_reader :schema, :from, :to, :options

      def initialize(schema, from, to, **options)
        @schema  = schema
        @from    = from
        @to      = to
        @options = options
      end

      def draw(image)
        return unless start && destination

        # paths = PathFinder.new(schema.path_map, start, destination).find
        finder = SchemaImageable::PathFinder.new(schema.path_map, start.near_position, destination.near_position)
        paths = finder.find

        paint = SchemaImageable::Draw.new(stroke_width: LINE_WIDTH, fill: "transparent", random_color: true)
        circle_paint = SchemaImageable::Draw.new(stroke_width: LINE_WIDTH, stroke: paint.options[:stroke])
        # m = SchemaImageable::Draw.new(pointsize: LINE_WIDTH, stroke: "green", fill: "transparent")

        # m.circle(finder.start.position.x, finder.start.position.y, 10)
        # paint.circle(finder.destination.position.x, finder.destination.position.y, 10)
        # m.circle(start.x, start.y, 10)
        # paint.circle(destination.x, destination.y, 10)
        #
        # finder.map.nodes.each do |node|
        #   if node.adjecent.empty?
        #     paint.text(node.position.x, node.position.y, "1")
        #   else
        #     m.text(node.position.x, node.position.y, "0")
        #   end
        # end
        paint.line(start.x, start.y, finder.start.position.x, finder.start.position.y)
        paint.polyline(*paths.map { |position| [position.x, position.y] }.flatten) unless paths.nil? || paths.empty?
        paint.line(destination.x, destination.y, finder.destination.position.x, finder.destination.position.y)

        circle_paint.circle(destination.x, destination.y, 5)
        paint.draw(image)
        circle_paint.draw(image)
        # m.draw(image)
      end

      def start
        @start ||=  if    to.center_position.x > from.right_center_position.x  then from.add_reference_port(:right)
                    elsif to.center_position.x < from.left_center_position.x   then from.add_reference_port(:left)
                    elsif to.center_position.y < from.top_center_position.y    then from.add_reference_port(:top)
                    elsif to.center_position.y > from.bottom_center_position.y then from.add_reference_port(:bottom)
                    end
      end

      def destination
        @destination ||=  if    from.center_position.x > to.right_center_position.x  then to.add_reference_port(:right)
                          elsif from.center_position.x < to.left_center_position.x   then to.add_reference_port(:left)
                          elsif from.center_position.y < to.top_center_position.y    then to.add_reference_port(:top)
                          elsif from.center_position.y > to.bottom_center_position.y then to.add_reference_port(:bottom)
                          end
      end
    end
  end
end
