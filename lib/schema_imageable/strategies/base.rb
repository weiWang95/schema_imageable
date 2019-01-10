
module SchemaImageable
  module Strategies
    class Base
      EXTENSION_WHITE_LIST = %w(jpg png jpeg)

      attr_reader :schema, :options

      def initialize(schema, **options)
        @schema  = schema
        @options = options
      end

      def write(image)
        output = options[:output] || "."
        raise "Dir not exist" unless Dir.exists?(output)

        extension = options[:extension] || "png"
        unless extension && EXTENSION_WHITE_LIST.include?(extension)
          raise "Error file extension: #{extension}, only support #{EXTENSION_WHITE_LIST.join(',')}"
        end

        output_file = File.new("#{output}/db_schema_#{Time.now.to_i}.#{extension}", "w")
        image.write("#{extension}:#{output_file.path}")
      end
    end
  end
end
