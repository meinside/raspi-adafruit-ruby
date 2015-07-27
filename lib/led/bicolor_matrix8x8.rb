require_relative "./matrix8x8"

module Adafruit
  module LED
    class BicolorMatrix8x8 < Matrix8x8
      OFF     = 0
      GREEN   = 1
      RED     = 2
      YELLOW  = 3

      def initialize(*args)
        @buffer = [0] * 16
        super
      end

      def clear
        fill OFF
      end

      def fill color=RED
        (0...MAX_ROW).each do |y|
          (0...MAX_COL).each do |x|
            set_pixel x, y, color
          end
        end

        write_display
      end

      def write(row, value)
        @device.write(@address, row, value)
      end

      def write_array(arr)
        arr.each_with_index do |x_values, y|
          raise "row #{y} has wrong number of elements: #{x.count}" if x_values.count != MAX_COL

          x_values.each_with_index do |value, x|
            set_pixel x, y, value
          end
        end

        write_display
      end

      def set_pixel x, y, value
        # Set green LED based on 1st bit in value.
        set_led y * 16 + x, ((value & GREEN).zero? ? 0 : 1)
        # Set red LED based on 2nd bit in value.
        set_led y * 16 + x + 8, ((value & RED).zero? ? 0 : 1)
      end

      def write_display
        @buffer.each_with_index do |value, i|
          write i, value
        end
      end

      def set_led led, value
        if led < 0 or led > 127
          raise "LED must be value of 0 to 127 but was #{led}"
        end
        # # Calculate position in byte buffer and bit offset of desired LED.
        pos = led / 8
        offset = led % 8
        if value.zero?
          # Turn off the specified LED (set bit to zero).
          @buffer[pos] &= ~(1 << offset)
        else
          # Turn on the speciried LED (set bit to one).
          @buffer[pos] |= (1 << offset)
        end
      end
    end
  end
end
