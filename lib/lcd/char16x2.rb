#!/usr/bin/env ruby
# coding: UTF-8

# lib/lcd/char16x2.rb
#
# Adafruit's 16x2 LCD Plate (http://adafruit.com/products/1109)
#
# * prerequisite: http://www.skpang.co.uk/blog/archives/575
# 
# created on : 2013.06.27
# last update: 2013.06.28
# 
# by meinside@gmail.com

# need 'i2c' gem installed
require "i2c/i2c"
require "i2c/backends/i2c-dev"

require_relative "../rpi"

# referenced: 
#   https://github.com/adafruit/Adafruit-Raspberry-Pi-Python-Code/blob/master/Adafruit_CharLCDPlate/Adafruit_CharLCDPlate.py
module Adafruit
  module LCD
    class Char16x2
      # Port expander registers
      MCP23017_IOCON_BANK0    = 0x0A  # IOCON when Bank 0 active
      MCP23017_IOCON_BANK1    = 0x15  # IOCON when Bank 1 active
      # These are register addresses when in Bank 1 only:
      MCP23017_GPIOA          = 0x09
      MCP23017_IODIRB         = 0x10
      MCP23017_GPIOB          = 0x19

      # Port expander input pin definitions
      SELECT                  = 0
      RIGHT                   = 1
      DOWN                    = 2
      UP                      = 3
      LEFT                    = 4

      # LED colors
      OFF                     = 0x00
      RED                     = 0x01
      GREEN                   = 0x02
      BLUE                    = 0x04
      YELLOW                  = RED + GREEN
      TEAL                    = GREEN + BLUE
      VIOLET                  = RED + BLUE
      WHITE                   = RED + GREEN + BLUE
      ON                      = RED + GREEN + BLUE

      # LCD Commands
      LCD_CLEARDISPLAY        = 0x01
      LCD_RETURNHOME          = 0x02
      LCD_ENTRYMODESET        = 0x04
      LCD_DISPLAYCONTROL      = 0x08
      LCD_CURSORSHIFT         = 0x10
      LCD_FUNCTIONSET         = 0x20
      LCD_SETCGRAMADDR        = 0x40
      LCD_SETDDRAMADDR        = 0x80

      # Flags for display on/off control
      LCD_DISPLAYON           = 0x04
      LCD_DISPLAYOFF          = 0x00
      LCD_CURSORON            = 0x02
      LCD_CURSOROFF           = 0x00
      LCD_BLINKON             = 0x01
      LCD_BLINKOFF            = 0x00

      # Flags for display entry mode
      LCD_ENTRYRIGHT          = 0x00
      LCD_ENTRYLEFT           = 0x02
      LCD_ENTRYSHIFTINCREMENT = 0x01
      LCD_ENTRYSHIFTDECREMENT = 0x00

      # Flags for display/cursor shift
      LCD_DISPLAYMOVE = 0x08
      LCD_CURSORMOVE  = 0x00
      LCD_MOVERIGHT   = 0x04
      LCD_MOVELEFT    = 0x00

      def initialize(device = RaspberryPi::i2c_device_path, address = 0x20)
        if device.kind_of? String
          @device = ::I2C.create(device)
        else
          [ :read, :write ].each do |m|
            raise IncompatibleDeviceException, 
            "Missing #{m} method in device object." unless device.respond_to?(m)
          end
          @device = device
        end
        @address = address

        # I2C is relatively slow.  MCP output port states are cached
        # so we don't need to constantly poll-and-change bit states.
        @porta, @portb, @ddrb = 0, 0, 0b00010000

        # Set MCP23017 IOCON register to Bank 0 with sequential operation.
        # If chip is already set for Bank 0, this will just write to OLATB,
        # which won't seriously bother anything on the plate right now
        # (blue backlight LED will come on, but that's done in the next
        # step anyway).
        @device.write(@address, MCP23017_IOCON_BANK1, 0x00)

        # Brute force reload ALL registers to known state.  This also
        # sets up all the input pins, pull-ups, etc. for the Pi Plate.
        @device.write(
          @address, 0, 
          *[0b00111111,  # IODIRA    R+G LEDs=outputs, buttons=inputs
            @ddrb ,       # IODIRB    LCD D7=input, Blue LED=output
            0b00111111,   # IPOLA     Invert polarity on button inputs
            0b00000000,   # IPOLB
            0b00000000,   # GPINTENA  Disable interrupt-on-change
            0b00000000,   # GPINTENB
            0b00000000,   # DEFVALA
            0b00000000,   # DEFVALB
            0b00000000,   # INTCONA
            0b00000000,   # INTCONB
            0b00000000,   # IOCON
            0b00000000,   # IOCON
            0b00111111,   # GPPUA     Enable pull-ups on buttons
            0b00000000,   # GPPUB
            0b00000000,   # INTFA
            0b00000000,   # INTFB
            0b00000000,   # INTCAPA
            0b00000000,   # INTCAPB
            @porta,       # GPIOA
            @portb,       # GPIOB
            @porta,       # OLATA     0 on all outputs; side effect of
            @portb])     # OLATB     turning on R+G+B backlight LEDs.

        # Switch to Bank 1 and disable sequential operation.
        # From this point forward, the register addresses do NOT match
        # the list immediately above.  Instead, use the constants defined
        # at the start of the class.  Also, the address register will no
        # longer increment automatically after this -- multi-byte
        # operations must be broken down into single-byte calls.
        @device.write(@address, MCP23017_IOCON_BANK0, 0b10100000)

        @displayshift = LCD_CURSORMOVE | LCD_MOVERIGHT
        @displaymode = LCD_ENTRYLEFT | LCD_ENTRYSHIFTDECREMENT
        @displaycontrol = LCD_DISPLAYON | LCD_CURSOROFF | LCD_BLINKOFF

        write(0x33) # Init
        write(0x32) # Init
        write(0x28) # 2 line 5x8 matrix
        write(LCD_CLEARDISPLAY)
        write(LCD_CURSORSHIFT    | @displayshift)
        write(LCD_ENTRYMODESET   | @displaymode)
        write(LCD_DISPLAYCONTROL | @displaycontrol)
        write(LCD_RETURNHOME)
        
        if block_given?
          yield self
        end
      end

      # The LCD data pins (D4-D7) connect to MCP pins 12-9 (PORTB4-1), in
      # that order.  Because this sequence is 'reversed,' a direct shift
      # won't work.  This table remaps 4-bit data values to MCP PORTB
      # outputs, incorporating both the reverse and shift.
      FLIP = [ 0b00000000, 0b00010000, 0b00001000, 0b00011000,
               0b00000100, 0b00010100, 0b00001100, 0b00011100,
               0b00000010, 0b00010010, 0b00001010, 0b00011010,
               0b00000110, 0b00010110, 0b00001110, 0b00011110 ]

      # Low-level 4-bit interface for LCD output.  This doesn't actually
      # write data, just returns a byte array of the PORTB state over time.
      # Can concatenate the output of multiple calls (up to 8) for more
      # efficient batch write.
      def out4(bitmask, value)
        hi = bitmask | FLIP[value >> 4]
        lo = bitmask | FLIP[value & 0x0F]
        return [hi | 0b00100000, hi, lo | 0b00100000, lo]
      end

      # The speed of LCD accesses is inherently limited by I2C through the
      # port expander.  A 'well behaved program' is expected to poll the
      # LCD to know that a prior instruction completed.  But the timing of
      # most instructions is a known uniform 37 mS.  The enable strobe
      # can't even be twiddled that fast through I2C, so it's a safe bet
      # with these instructions to not waste time polling (which requires
      # several I2C transfers for reconfiguring the port direction).
      # The D7 pin is set as input when a potentially time-consuming
      # instruction has been issued (e.g. screen clear), as well as on
      # startup, and polling will then occur before more commands or data
      # are issued.
      POLLABLES = [ LCD_CLEARDISPLAY, LCD_RETURNHOME ]

      # Write byte, list or string value to LCD
      def write(value, char_mode = false)
        # If pin D7 is in input state, poll LCD busy flag until clear.
        if @ddrb & 0b00010000
          lo = (@portb & 0b00000001) | 0b01000000
          hi = lo | 0b00100000 # E=1 (strobe)
          @device.write(@address, MCP23017_GPIOB, lo)
          while true
            # Strobe high (enable)
            @device.write(@address, hi)
            # First nybble contains busy state
            bits = @device.read(@address, 1).unpack("C").first

            # Strobe low, high, low.  Second nybble (A3) is ignored.
            @device.write(@address, MCP23017_GPIOB, *[lo, hi, lo])
            break if (bits & 0b00000010) == 0 # D7=0, not busy
          end
          
          @portb = lo

          # Polling complete, change D7 pin to output
          @ddrb &= 0b11101111
          @device.write(@address, MCP23017_IODIRB, @ddrb)
        end

        bitmask = @portb & 0b00000001   # Mask out PORTB LCD control bits
        bitmask |= 0b10000000 if char_mode  # Set data bit if not a command

        # If string or list, iterate through multiple write ops
        if value.respond_to? :each_line
          last = value.length - 1 # Last character in string
          data = []             # Start with blank list
          value.each_byte.each_with_index{|v, i|
            # Append 4 bytes to list representing PORTB over time.
            # First the high 4 data bits with strobe (enable) set
            # and unset, then same with low 4 data bits (strobe 1/0).
            data += out4(bitmask, v.ord)
            # I2C block data write is limited to 32 bytes max.
            # If limit reached, write data so far and clear.
            # Also do this on last byte if not otherwise handled.
            if data.size >= 32 || i == last
              @device.write(@address, MCP23017_GPIOB, *data)
              @portb = data[-1] # Save state of last byte out
              data       = [] # Clear list for next iteration
            end
          }
        elsif value.respond_to? :each
          # Same as above, but for list instead of string
          last = value.size - 1
          data = []
          value.each_with_index{|v, i|
            data += out4(bitmask, v)
            if data.size >= 32 || i == last
              @device.write(@address, MCP23017_GPIOB, *data)
              @portb = data[-1]
              data       = []
            end
          }
        else
          # Single byte
          data = out4(bitmask, value)
          @device.write(@address, MCP23017_GPIOB, *data)
          @portb = data[-1]
        end
          
        # If a poll-worthy instruction was issued, reconfigure D7
        # pin as input to indicate need for polling on next call.
        if !char_mode && POLLABLES.include?(value)
          @ddrb |= 0b00010000
          @device.write(@address, MCP23017_IODIRB, @ddrb)
        end
      end

      # ----------------------------------------------------------------------
      # Utility methods

      def begin(cols, lines)
        @currline = 0
        @numlines = lines
        clear
      end

      # Puts the MCP23017 back in Bank 0 + sequential write mode so
      # that other code using the 'classic' library can still work.
      # Any code using this newer version of the library should
      # consider adding an atexit() handler that calls this.
      def stop
        @porta = 0b11000000  # Turn off LEDs on the way out
        @portb = 0b00000001
        sleep(0.0015)
        @device.write(@address, MCP23017_IOCON_BANK1, 0)
        @device.write(@address, 0, 
          *[0b00111111,   # IODIRA
            @ddrb,        # IODIRB
            0b00000000,   # IPOLA
            0b00000000,   # IPOLB
            0b00000000,   # GPINTENA
            0b00000000,   # GPINTENB
            0b00000000,   # DEFVALA
            0b00000000,   # DEFVALB
            0b00000000,   # INTCONA
            0b00000000,   # INTCONB
            0b00000000,   # IOCON
            0b00000000,   # IOCON
            0b00111111,   # GPPUA
            0b00000000,   # GPPUB
            0b00000000,   # INTFA
            0b00000000,   # INTFB
            0b00000000,   # INTCAPA
            0b00000000,   # INTCAPB
            @porta,       # GPIOA
            @portb,       # GPIOB
            @porta,       # OLATA
            @portb])      # OLATB
      end

      def clear
        write(LCD_CLEARDISPLAY)
      end

      def home
        write(LCD_RETURNHOME)
      end

      ROW_OFFSETS = [ 0x00, 0x40, 0x14, 0x54 ]

      def set_cursor(col, row)
        if row > @numlines
          row = @numlines - 1
        elsif row < 0
          row = 0
        end
        write(LCD_SETDDRAMADDR | (col + ROW_OFFSETS[row]))
      end

      # Turn the display on (quickly)
      def display
        @displaycontrol |= LCD_DISPLAYON
        write(LCD_DISPLAYCONTROL | @displaycontrol)
      end

      # Turn the display off (quickly)
      def no_display
        @displaycontrol &= ~LCD_DISPLAYON
        write(LCD_DISPLAYCONTROL | @displaycontrol)
      end

      # Underline cursor on
      def cursor
        @displaycontrol |= LCD_CURSORON
        write(LCD_DISPLAYCONTROL | @displaycontrol)
      end

      # Underline cursor off
      def no_cursor
        @displaycontrol &= ~LCD_CURSORON
        write(LCD_DISPLAYCONTROL | @displaycontrol)
      end

      # Toggles the underline cursor On/Off
      def toggle_cursor
        @displaycontrol ^= LCD_CURSORON
        write(LCD_DISPLAYCONTROL | @displaycontrol)
      end

      # Turn on the blinking cursor
      def blink
        @displaycontrol |= LCD_BLINKON
        write(LCD_DISPLAYCONTROL | @displaycontrol)
      end

      # Turn off the blinking cursor
      def no_blink
        @displaycontrol &= ~LCD_BLINKON
        write(LCD_DISPLAYCONTROL | @displaycontrol)
      end

      # Toggles the blinking cursor
      def toggle_blink
        @displaycontrol ^= LCD_BLINKON
        write(LCD_DISPLAYCONTROL | @displaycontrol)
      end

      # These commands scroll the display without changing the RAM
      def scroll_display_left
        @displayshift = LCD_DISPLAYMOVE | LCD_MOVELEFT
        write(LCD_CURSORSHIFT | @displayshift)
      end

      # These commands scroll the display without changing the RAM
      def scroll_display_right
        @displayshift = LCD_DISPLAYMOVE | LCD_MOVERIGHT
        write(LCD_CURSORSHIFT | @displayshift)
      end

      # This is for text that flows left to right
      def left_to_right
        @displaymode |= LCD_ENTRYLEFT
        write(LCD_ENTRYMODESET | @displaymode)
      end

      # This is for text that flows right to left
      def right_to_left
        @displaymode &= ~LCD_ENTRYLEFT
        write(LCD_ENTRYMODESET | @displaymode)
      end

      # This will 'right justify' text from the cursor
      def autoscroll
        @displaymode |= LCD_ENTRYSHIFTINCREMENT
        write(LCD_ENTRYMODESET | @displaymode)
      end

      # This will 'left justify' text from the cursor
      def no_autoscroll
        @displaymode &= ~LCD_ENTRYSHIFTINCREMENT
        write(LCD_ENTRYMODESET | @displaymode)
      end

      def create_char(location, bitmap)
        write(LCD_SETCGRAMADDR | ((location & 7) << 3))
        write(bitmap, true)
        write(LCD_SETDDRAMADDR)
      end

      # Send string to LCD. Newline wraps to second line
      def message(text)
        text.split("\n").each_with_index{|line, i| # Split at newline(s)
          write(0xC0) if i > 0  # If newline(s), set DDRAM address to 2nd line
          write(line, true)     # Issue substring
        }
      end

      def backlight(color)
        c = ~color
        @porta = (@porta & 0b00111111) | ((c & 0b011) << 6)
        @portb = (@portb & 0b11111110) | ((c & 0b100) >> 2)
        # Has to be done as two writes because sequential operation is off.
        @device.write(@address, MCP23017_GPIOA, @porta)
        @device.write(@address, MCP23017_GPIOB, @portb)
      end

      # Read state of single button
      def button_pressed(b)
        return (@device.read(@address, 1, MCP23017_GPIOA).unpack("C").first >> b) & 1 > 0
      end

      # Read and return bitmask of combined button state
      def buttons
        return @device.read(@address, 1, MCP23017_GPIOA).unpack("C").first & 0b11111
      end
    end
  end
end

