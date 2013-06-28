#!/usr/bin/env ruby
# coding: UTF-8

# lib/led/matrix8x8.rb
#
# Adafruit's 8x8 LED matrix (http://adafruit.com/products/959)
#
# * prerequisite: http://www.skpang.co.uk/blog/archives/575
# 
# created on : 2012.09.12
# last update: 2013.06.28
# 
# by meinside@gmail.com

# need 'i2c' gem installed
require "i2c/i2c"
require "i2c/backends/i2c-dev"

require_relative "../rpi"

# referenced: 
#   https://github.com/adafruit/Adafruit-Raspberry-Pi-Python-Code/blob/master/Adafruit_LEDBackpack/Adafruit_LEDBackpack.py
module Adafruit
  module LED
    class Matrix8x8
      # Registers
      HT16K33_REGISTER_DISPLAY_SETUP        = 0x80
      HT16K33_REGISTER_SYSTEM_SETUP         = 0x20
      HT16K33_REGISTER_DIMMING              = 0xE0

      # Blink rate
      HT16K33_BLINKRATE_OFF                 = 0x00
      HT16K33_BLINKRATE_2HZ                 = 0x01
      HT16K33_BLINKRATE_1HZ                 = 0x02
      HT16K33_BLINKRATE_HALFHZ              = 0x03

      MAX_COL = 8
      MAX_ROW = 8

      def initialize(device = RaspberryPi::i2c_device_path, address = 0x70, options = {blink_rate: HT16K33_BLINKRATE_OFF, brightness: 15})
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

        # turn on oscillator
        @device.write(@address, HT16K33_REGISTER_SYSTEM_SETUP | 0x01, 0x00)

        # set blink rate and brightness
        set_blink_rate(options[:blink_rate])
        set_brightness(options[:brightness])

        if block_given?
          yield self
        end
      end

      def set_blink_rate(rate)
        rate = HT16K33_BLINKRATE_OFF if rate > HT16K33_BLINKRATE_HALFHZ
        @device.write(@address, HT16K33_REGISTER_DISPLAY_SETUP | 0x01 | (rate << 1), 0x00)
      end

      def set_brightness(brightness)
        brightness = 15 if brightness > 15
        @device.write(@address, HT16K33_REGISTER_DIMMING | brightness, 0x00)
      end

      def clear
        (0...MAX_ROW).each{|n| write(n, 0x00)}
      end

      def fill
        (0...MAX_ROW).each{|n| write(n, 0xFF)}
      end

      def write(row, value)
        value = (value << MAX_COL - 1) | (value >> 1)
        @device.write(@address, row * 2, value & 0xFF)
        @device.write(@address, row * 2 + 1, value >> MAX_COL)
      end

      def write_array(arr)
        raise "given array has wrong number of elements: #{arr.count}" if arr.count != MAX_ROW
        arr.each_with_index{|e, i|
          if e.kind_of? Array
            raise "row #{i} has wrong number of elements: #{e.count}" if e.count != MAX_COL
            # XXX - reverse horizontally
            e = e.reverse.map{|x| (x.to_i > 0 || x =~ /o/i) ? 1 : 0}.inject(0){|x, y| (x << 1) + y}
          end
          write(i, e.to_i)
        }
      end

      def read(row)
        @device.read(@address, 2, row * 2).unpack("C")[0]
      end
    end
  end
end

