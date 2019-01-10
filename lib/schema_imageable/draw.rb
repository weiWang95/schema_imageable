require "RMagick"

module SchemaImageable
  class Draw < ::Magick::Draw
    def initialize(**options)
      super()

      init_draw_config(options)
    end

    def roundrectangle(x1, y1, w, h)
      super(x1, y1, x1 + w, y1 + h, 8, 8)
    end

    private

      def init_draw_config(options)
        options[:stroke] = random_color if options[:random_color]
        self.fill        = options[:fill] || "black"
        self.stroke      = options[:stroke] || "black"
        self.pointsize   = options[:pointsize] || 16
        self.font_weight = options[:font_weight] || 100
      end

      def random_color
        arr = 3.times.map { rand(256).to_i.to_s }
        "rgb(#{arr.join(',')})"
      end
  end
end
