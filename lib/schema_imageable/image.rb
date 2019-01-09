require "RMagick"

module SchemaImageable
  class Image < ::Magick::Image
    def initialize(**options)
      width   = options[:width] || 2000
      height  = options[:height] || 1400

      super(width, height) do
        self.background_color = options[:background_color] || "Transparent"
      end
    end
  end
end