#!/usr/bin/env ruby
# coding: UTF-8

# test/lcd/char16x2.rb
#
# test script for
# Adafruit's 16x2 LCD Plate (http://adafruit.com/products/1109)
# 
# created on : 2013.06.27
# last update: 2013.06.28
# 
# by meinside@gmail.com

require_relative "../../lib/lcd/char16x2"

if __FILE__ == $0

  Adafruit::LCD::Char16x2.new{|lcd|
    lcd.clear
    lcd.backlight(Adafruit::LCD::Char16x2::WHITE)
    lcd.message("life is like\nriding a bicycle")

    while true
      buttons = lcd.buttons
      case
      when (buttons >> Adafruit::LCD::Char16x2::SELECT) & 1 > 0
        puts "SELECT pressed"
      when (buttons >> Adafruit::LCD::Char16x2::LEFT) & 1 > 0
        puts "LEFT pressed"
      when (buttons >> Adafruit::LCD::Char16x2::RIGHT) & 1 > 0
        puts "RIGHT pressed"
      when (buttons >> Adafruit::LCD::Char16x2::UP) & 1 > 0
        puts "UP pressed"
      when (buttons >> Adafruit::LCD::Char16x2::DOWN) & 1 > 0
        puts "DOWN pressed"
      end
      sleep 0.1
    end
  }

end

