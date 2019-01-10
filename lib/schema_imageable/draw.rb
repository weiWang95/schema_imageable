require "RMagick"

module SchemaImageable
  class Draw < ::Magick::Draw
    attr_reader :options
    def initialize(**options)
      @options = options
      super()

      init_draw_config
    end

    def roundrectangle(x1, y1, w, h)
      super(x1, y1, x1 + w, y1 + h, 8, 8)
    end

    def circle(x, y, radius)
      super(x, y, x + radius.abs, y)
    end

    private

      def init_draw_config
        options[:stroke] = random_color if options[:random_color]
        self.fill        = options[:fill] || "black"
        self.stroke      = options[:stroke] || "black"
        self.pointsize   = options[:pointsize] || 16
        self.font_weight = options[:font_weight] || 100
        self.stroke_width = options[:stroke_width] || 1
      end

      def random_color
        arr = 3.times.map { rand(256).to_i.to_s }
        "rgb(#{arr.join(',')})"
      end
  end
end
