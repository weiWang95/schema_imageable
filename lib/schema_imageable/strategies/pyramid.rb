require_relative "../position"

module SchemaImageable
  module Strategies
    class Pyramid < Base
      MARGIN = 60

      def generate
        SchemaImageable::Element::Table.include(TableExpand)

        calculate_tables_depth!
        width, height = calculate_image_dimension

        image = SchemaImageable::Image.new(width: width, height: height)
        schema.image = image

        schema.tables.each { |table| table.draw(image) }
        schema.references.each { |reference| reference.draw(image) }

        write(image)
      end

      private
        def calculate_tables_depth!
          dispose_nodes_relationship!
          dispose_root_node!
          dispose_layer_depth(root.children)
        end

        def calculate_image_dimension
          width, height = MARGIN, 0

          layer_nodes.each_with_index do |nodes, _depth|
            next if nodes.nil? || nodes.empty?

            max_width = nodes.max { |node| node.table.width }.table.width
            deviation = nodes.size / 2

            width += max_width + deviation * 2 * MARGIN
            x, y = width, MARGIN

            distance = deviation * 2 * MARGIN / nodes.size
            deviation = 0 - deviation
            deviation += 1 if nodes.size.even?

            nodes.each do |node|
              node.table.position = SchemaImageable::Position.new(x - max_width - deviation.abs * distance, y)

              deviation += 1
              y += node.table.height + MARGIN
            end

            width += MARGIN
            height = y if y > height
          end

          [width, height]
        end

        def root
          @root ||= Node.new(nil)
        end

        def nodes
          nodes_map.values
        end

        def nodes_map
          @table_node_map ||= schema.tables.each_with_object({}) do |table, map|
            map[table] = Node.new(table)
          end
        end

        def layer_nodes
          @layer_nodes ||= begin
            nodes.each_with_object([]) do |node, arr|
              arr[node.depth] ||= []
              arr[node.depth] << node
            end.compact.map do |nodes|
              nodes.sort_by!(&:children_count)

              direction = :unshift
              normality_nodes = nodes.reverse_each.with_object([]) do |node, res|
                res.send(direction, node)
                direction = direction == :unshift ? :push : :unshift
              end

              normality_nodes
            end
          end
        end

        def dispose_nodes_relationship!
          schema.references.each do |reference|
            from_node = nodes_map[reference.from]
            to_node   = nodes_map[reference.to]

            from_node.children << to_node
            to_node.parents << from_node
          end
        end

        def dispose_root_node!
          nodes.each do |node|
            next unless node.parents.empty?

            root.children << node
          end
        end

        def dispose_layer_depth(nodes, depth = 1)
          nodes.each do |node|
            if node.depth < depth
              node.depth = depth
            end

            dispose_layer_depth(node.children, depth + 1)
          end
        end

      class Node
        attr_accessor :table, :parents, :children

        def initialize(table)
          table.depth = 0 if table
          @table = table

          @parents  = []
          @children = []
        end

        def depth
          table.depth
        end

        def depth=(depth)
          table.depth = depth
        end

        def children_count
          children.count
        end
      end

      module TableExpand
        def self.included(base)
          base.class_eval do
            attr_accessor :depth
          end
        end
      end
    end
  end
end
