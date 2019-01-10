require_relative "position"
require "byebug"


module SchemaImageable
  class PathFinder
    attr_accessor :map, :reachable, :explored, :start, :destination

    def initialize(map, start, destination)
      @map         = map
      @start       = map.find(start.x / Map::SCALING, start.y / Map::SCALING)
      @destination = map.find(destination.x / Map::SCALING, destination.y / Map::SCALING)

      @explored  = []
      @reachable = [@start]

      map.nodes.each(&:clear)
    end

    def find
      current_node = reachable.first

      while current_node != destination
        explored << current_node
        reachable.delete_at(reachable.index(current_node))

        add_ajacent(current_node)

        return if reachable.size.zero?
        current_node = lowerst_node
      end

      paths = [destination.position]
      node = destination
      while !node.parent.nil?
        paths.unshift(node.parent.position)
        node = node.parent
      end

      paths
    end

    def add_ajacent(node)
      node.adjecent.each do |adj|
        next if explored.include?(adj) || reachable.include?(adj)

        adj.parent = node
        adj.value = calculate_node_value(adj, destination)
        reachable << adj
      end
    end

    def calculate_node_value(node, other_node)
      (node.row - other_node.row).abs + (node.col - other_node.col).abs
    end

    def lowerst_node
      min = map.cols + map.rows
      min_node = nil

      reachable.each do |node|
        next if node.value >= min

        min_node = node
        min = node.value
      end

      min_node
    end

    class Node
      attr_accessor :parent, :value, :adjecent, :row, :col, :position

      def initialize(row = nil, col = nil, x: nil, y: nil)
        raise ArgumentError if (row.nil? || col.nil?) && (x.nil? || y.nil?)

        @row = row || y / Map::SCALING
        @col = col || x / Map::SCALING
        @adjecent = []

        x = x || col * Map::SCALING + Map::SCALING / 2
        y = y || row * Map::SCALING + Map::SCALING / 2
        @position = SchemaImageable::Position.new(x, y)
      end

      def top_position
        SchemaImageable::Position.new(position.x, position.y - Map::SCALING)
      end

      def bottom_position
        SchemaImageable::Position.new(position.x, position.y + Map::SCALING)
      end

      def left_position
        SchemaImageable::Position.new(position.x - Map::SCALING, position.y)
      end

      def right_position
        SchemaImageable::Position.new(position.x + Map::SCALING, position.y)
      end

      def clear
        self.parent = nil
        self.value  = 0
      end

      def inspect
        "<Node:: row: #{row}, col: #{col}, parent: #{parent.inspect}, adjecent size: #{adjecent.size}>"
      end
    end

    class Map
      SCALING = 5

      attr_accessor :schema, :rows, :cols, :nodes, :ignore_nodes

      def initialize(schema)
        @schema = schema
        @nodes  = []

        @rows = schema.image.height / SCALING + 1
        @cols = schema.image.width  / SCALING + 1

        @ignore_nodes = schema.references.map do |r|
          [ Node.new(x: r.start.x, y: r.start.y), Node.new(x: r.destination.x, y: r.destination.y) ]
        end.flatten(1)

        init_nodes
      end

      def wall?(position)
        schema.table_include_position?(position)
      end

      def ignore?(node)
        ignore_position?(node)# || ignore_range?(node)
      end

      def ignore_position?(node)
        !ignore_nodes.find { |n| n.row == node.row && n.col == node.col }.nil?
      end

      def ignore_range?(node)
        ignore_nodes.any? { |n| distance(n, node) < 30 }
      end

      def distance(node1, node2)
        ((node1.position.y - node2.position.y) ** 2 + (node1.position.x - node2.position.x) ** 2) ** (1.0 / 2)
      end

      def reachable?(node)
        ignore?(node) || !wall?(node.position)
      end

      def find(col, row)
        nodes.find { |node| node.row == row && node.col == col }
      end

      def init_nodes
        (rows * cols).times do |i|
          row = i / cols
          nodes << Node.new(row, i - (row * cols))
        end

        nodes.each do |node|
          next if !ignore?(node) && wall?(node.position)
          row = node.row
          col = node.col

          # node.adjecent << nodes[cols * (row - 1) + col] if row > 0 && !wall?(node.top_position)  # top
          # node.adjecent << nodes[cols * row + col + 1  ] if col < cols - 1 && !wall?(node.right_position)  # right
          # node.adjecent << nodes[cols * (row + 1) + col] if row > rows - 1 && !wall?(node.bottom_position)  # bottom
          # node.adjecent << nodes[cols * row + col - 1  ] if col > 0 && !wall?(node.left_position)  # left
          node.adjecent << nodes[cols * (row - 1) + col] if row > 0        && reachable?(nodes[cols * (row - 1) + col])  # top
          node.adjecent << nodes[cols * row + col + 1  ] if col < cols - 1 && reachable?(nodes[cols * row + col + 1  ])  # right
          node.adjecent << nodes[cols * (row + 1) + col] if row < rows - 1 && reachable?(nodes[cols * (row + 1) + col])  # bottom
          node.adjecent << nodes[cols * row + col - 1  ] if col > 0        && reachable?(nodes[cols * row + col - 1  ])  # left
        end
      end
    end
  end
end