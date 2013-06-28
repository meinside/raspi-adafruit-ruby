#!/usr/bin/env ruby
# coding: UTF-8

# lib/rpi.rb
#
# utility functions for raspberry pi
#
# created on : 2013.06.28
# last update: 2013.06.28
# 
# by meinside@gmail.com

class RaspberryPi
  def self.board_revision
    File.open("/proc/cpuinfo", "r"){|file|
      return ["2", "3"].include?(file.each_line.find{|x| x =~ /^Revision/}.strip[-1]) ? 1 : 2
    }
  end

  def self.i2c_device_path
    case self.board_revision
    when 1
      return "/dev/i2c-0"
    when 2
      return "/dev/i2c-1"
    end
  end
end

