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
          width  = MARGIN
          height = layer_nodes.map { |nodes| nodes.sum { |node| node.table.height } + (nodes.size + 1) * MARGIN }.max

          layer_nodes.each_with_index do |nodes, _depth|
            next if nodes.nil? || nodes.empty?

            max_width = nodes.max { |node| node.table.width }.table.width

            width += max_width + 4 * MARGIN
            x = width
            y = (height - nodes.sum { |node| node.table.height } - (nodes.size - 1) * MARGIN) / 2

            nodes.each do |node|
              node.table.position = SchemaImageable::Position.new(x - max_width - 2 * MARGIN, y)

              y += node.table.height + MARGIN
            end

            width += 2 * MARGIN
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
            depth_nodes = nodes.each_with_object([]) do |node, arr|
              arr[node.depth] ||= []
              arr[node.depth] << node
            end.compact

            prev_nodes = []
            depth_nodes.map do |nodes|
              normality_nodes = nodes.sort_by do |node|
                compute_node_inclination_score(node, prev_nodes)
              end

              half = normality_nodes.size / 2
              middle_index = half + (normality_nodes.size.odd? ? 0 : -1)

              (normality_nodes.size - 1).times do |index|
                node = normality_nodes[index]
                next_node = normality_nodes[index + 1]

                if index < middle_index && node.children_count > next_node.children_count
                  normality_nodes[index], normality_nodes[index + 1] = next_node, node
                elsif index >= middle_index && node.children_count < next_node.children_count
                  normality_nodes[index], normality_nodes[index + 1] = next_node, node
                end
              end

              prev_nodes = normality_nodes
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

        def compute_node_inclination_score(node, nodes)
          score = 0
          half = nodes.size / 2
          middle_index = half + (nodes.size.odd? ? 1 : 0)

          node.parents.each do |parent|
            index = nodes.index(parent)
            next if index.nil?

            score += (index - middle_index) / half.to_f + (index >= middle_index ? 0.1 : - 0.1)
          end

          score
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
