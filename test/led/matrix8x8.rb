#!/usr/bin/env ruby
# coding: UTF-8

# test/led/matrix8x8.rb
#
# test script for
# Adafruit's 8x8 LED matrix (http://adafruit.com/products/959)
# 
# created on : 2013.06.27
# last update: 2013.06.28
# 
# by meinside@gmail.com

require_relative "../../lib/led/matrix8x8"

if __FILE__ == $0

  Adafruit::LED::Matrix8x8.new{|led|
    # smile!
    led.write_array([
      [0, 0, 1, 1, 1, 1, 0, 0],
      [0, 1, 0, 0, 0, 0, 1, 0],
      [1, 0, 1, 0, 0, 1, 0, 1],
      [1, 0, 1, 0, 0, 1, 0, 1],
      [1, 1, 0, 0, 0, 0, 1, 1],
      [1, 0, 1, 1, 1, 1, 0, 1],
      [0, 1, 0, 0, 0, 0, 1, 0],
      [0, 0, 1, 1, 1, 1, 0, 0],
    ])

    sleep 3

    led.clear
  }

end

