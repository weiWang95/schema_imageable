require_relative "strategies/base"
require_relative "strategies/default"

module SchemaImageable
  class Strategy
    class << self
      def dispatch(schema, **options)
        raise "Invalid Strategy" unless !options[:strategy] || options[:strategy].ancestors.include?(SchemaImageable::Strategies::Base)
        (options[:strategy] || SchemaImageable::Strategies::Default).new(schema)
      end
    end
  end
end
