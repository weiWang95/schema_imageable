require_relative "element/table"
require_relative "element/reference"
require_relative "image"

module SchemaImageable
  class Schema
    module DSL
      def create_table(name, **options)
        table = Element::Table.new(name, options)
        table.add_column("primary", "id")

        yield(table) if block_given?

        tables << table
      end

      def add_foreign_key(to, from, **options)
        references << Element::Reference.new(from, to, options)
      end
    end
    include DSL

    EXTENSION_WHITE_LIST = %w(jpg png jpeg)

    attr_reader :path, :output, :options, :tables, :references

    def initialize(path, output = ".", **options)
      @path       = path
      @output     = output
      @options    = options
      @tables     = []
      @references = []
    end

    def generate
      load_schema_data

      sort_tables_by_score!

      generate_schema_image

      write_schema_image
    end

    def image
      @image ||= Image.new(options)
    end

    private

      def load_schema_data
        raise "File not exist" unless File.exists?(path)

        load(path)
        instance_eval(&::ActiveRecord::Schema.schema_proc)
      end

      def generate_schema_image
        x, y = 60, 60
        tables.reverse_each do |table|
          position = calculate_table_position(table)
          table.draw(image, x, y)
          x = x + table.width + 30
        end
        # references.each()
      end

      def write_schema_image
        raise "Dir not exist" unless Dir.exists?(output)

        extension = options[:extension] || "png"
        unless extension && EXTENSION_WHITE_LIST.include?(extension)
          raise "Error file extension: #{extension}, only support #{EXTENSION_WHITE_LIST.join(',')}"
        end

        output_file = File.new("#{output}/db_schema_#{Time.now.to_i}.#{extension}", "w")
        image.write("#{extension}:#{output_file.path}")
      end

      def sort_tables_by_score!
        reference_count_map = references.each_with_object({}) do |reference, map|
          key = reference.from
          map[key] = (map[key] || 0) + 1
        end

        # r * 0.8 + w * 0.2
        tables.sort_by! do |table|
          (reference_count_map[table.name] || 0) * 0.8 + table.columns.size * 0.2
        end
      end

      def calculate_table_position(table)
        [100, 100]
      end
  end
end