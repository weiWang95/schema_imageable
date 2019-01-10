require_relative "element/table"
require_relative "element/reference"
require_relative "image"
require_relative "strategy"
require_relative "path_finder"

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
        references << Element::Reference.new(self, table_map[from], table_map[to], options)
      end
    end
    include DSL

    attr_reader :path, :options, :tables, :references
    attr_accessor :image, :path_map

    def initialize(path, **options)
      @path       = path
      @options    = options
      @tables     = []
      @references = []
    end

    def generate
      load_schema_data

      generate_schema_image
    end

    def table_map
      @table_map ||= tables.each_with_object({}) { |table, map| map[table.name] = table }
    end

    def table_include_position?(position)
      tables.any? { |table| table.include_position?(position) }
    end

    def path_map
      @path_map ||= SchemaImageable::PathFinder::Map.new(self)
    end

    private

      def load_schema_data
        raise "File not exist" unless File.exists?(path)

        load(path)
        instance_eval(&::ActiveRecord::Schema.schema_proc)
      end

      def generate_schema_image
        Strategy.dispatch(self, options).generate
      end
  end
end