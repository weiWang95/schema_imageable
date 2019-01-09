module SchemaImageable
  module Element
    class Reference
      attr_reader :from, :to, :options

      def initialize(from, to, **options)
        @from    = from
        @to      = to
        @options = options
      end

      def draw(image)

      end
    end
  end
end
