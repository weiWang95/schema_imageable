require "RMagick"

module SchemaImageable
  class Image < ::Magick::Image
    attr_accessor :width, :height

    def initialize(**options)
      @width   = options[:width] || 1440
      @height  = options[:height] || 768

      super(@width, @height) do
        self.background_color = options[:background_color] || "Transparent"
      end
    end
  end
end