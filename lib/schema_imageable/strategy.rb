require_relative "strategies/base"
require_relative "strategies/default"
require_relative "strategies/pyramid"

module SchemaImageable
  class Strategy
    class << self
      def dispatch(schema, **options)
        raise "Invalid Strategy" unless !options[:strategy] || options[:strategy].ancestors.include?(SchemaImageable::Strategies::Base)
        (options[:strategy] || SchemaImageable::Strategies::Pyramid).new(schema)
      end
    end
  end
end
