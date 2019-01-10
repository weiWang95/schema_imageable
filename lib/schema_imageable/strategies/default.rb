require_relative "../position"

module SchemaImageable
  module Strategies
    class Default < Base
      MARGIN = 30

      def generate
        sort_schema_tables!
        width, height = calculate_image_dimension

        image = SchemaImageable::Image.new(width: width, height: height)
        schema.image = image

        schema.tables.reverse_each { |table| table.draw(image) }
        schema.references.each { |reference| reference.draw(image) }

        write(image)
      end

      private
        def calculate_image_dimension
          BoxingArithmetic.new(schema.tables).calculate
        end

        def sort_schema_tables!
          # reference_count_map = schema.references.each_with_object({}) do |reference, map|
          #   key = reference.from
          #   map[key] = (map[key] || 0) + 1
          # end
          #
          # # r * 0.8 + w * 0.2
          # schema.tables.sort_by! do |table|
          #   (reference_count_map[table.name] || 0) * 0.8 + table.columns.size * 0.2
          # end
          schema.tables.sort_by! { |table| (table.width + MARGIN) * (table.height + MARGIN) }
        end

      class BoxingArithmetic
        attr_accessor :box, :tables

        def initialize(tables)
          @tables = tables
          @box    = Node.new(tables[-1].width + 2 * MARGIN, tables[-1].height + 2 * MARGIN, 0, 0, true)
        end

        def calculate
          tables.reverse_each.with_index do |table, index|
            if index.zero?
              fit_node = box
            else
              width  = table.width + 2 * MARGIN
              height = table.height + 2 * MARGIN

              node = find_node(box, width, height)
              fit_node =  if node
                            split_node(node, width, height)
                          else
                            grow_box(width, height)
                          end
            end
            table.position = SchemaImageable::Position.new(fit_node.x + MARGIN, fit_node.y + MARGIN)
          end

          [box.w, box.h]
        end

        def find_node(node, w, h)
          return unless node

          if node.used
            find_node(node.right, w, h) || find_node(node.down, w, h)
          elsif w <= node.w && h <= node.h
            node
          else
            nil
          end
        end

        def split_node(node, w, h)
          node.used  = true
          node.down  = Node.new(node.w    , node.h - h, node.x    , node.y + h)
          node.right = Node.new(node.w - w, node.h    , node.x + w, node.y    )
          node
        end

        def grow_box(w, h)
          can_grow_down  = w <= box.w
          can_grow_right = h <= box.h

          should_grow_right = can_grow_right && box.h >= (box.w + w)
          should_grow_down  = can_grow_down  && box.w >= (box.h + h)

          if    should_grow_down  then grow_down(w, h)
          elsif should_grow_right then grow_right(w, h)
          elsif can_grow_down     then grow_down(w, h)
          elsif can_grow_right    then grow_right(w, h)
          end
        end

        def grow_right(w, h)
          right = Node.new(w, box.h, box.w, 0)
          self.box = Node.new(box.w + w, box.h, 0, 0, true, down: box, right: right)

          if node = find_node(box, w, h)
            split_node(node, w, h)
          end
        end

        def grow_down(w, h)
          down = Node.new(box.w, h, 0, box.h)
          self.box = Node.new(box.w, box.h + h, 0, 0, true, down: down, right: box)

          if node = find_node(box, w, h)
            split_node(node, w, h)
          end
        end
      end

      class Node
        attr_accessor :used, :down, :right, :x, :y, :w, :h

        def initialize(w, h, x, y, used = false, down: nil, right: nil)
          @w, @h, @x, @y, @used = w, h, x, y, used
          @down, @right = down, right
        end
      end
    end
  end
end
