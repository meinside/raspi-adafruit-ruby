## Ruby code snippets for Raspberry Pi peripherals from Adafruit ##
by Sungjin Han <meinside@gmail.com>

### Description ###

Ruby scripts for various Raspberry Pi peripherals from Adafruit

### Instructions ###

#### a. setup i2c ####

``$ sudo modprobe i2c_dev``

``$ sudo vi /etc/modules``

```
# Add following line:

i2c-dev
```

``$ sudo vi /etc/modprobe.d/raspi-blacklist.conf ``

```
# Comment out following lines:

blacklist spi-bcm2708
blacklist i2c-bcm2708
```

``$ sudo apt-get install i2c-tools``

``$ sudo usermod -a -G i2c USERNAME``


# Install gem

`gem install raspi-adafruit-ruby`

### Examples

# 8x8 Matrix

```ruby
require 'led/matrix8x8'

Adafruit::LED::Matrix8x8.new do |led|
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
  sleep 3

  led.fill
end
```

# Bicolor 8x8 Matrix

```ruby
require 'led/bicolor_matrix8x8'

OFF     = 0
GREEN   = 1
RED     = 2
YELLOW  = 3

Adafruit::LED::BicolorMatrix8x8.new do|led|
  led.write_array([
    [RED, RED, GREEN, GREEN, YELLOW, YELLOW, OFF, GREEN],
    [RED, RED, GREEN, GREEN, YELLOW, YELLOW, OFF, GREEN],
    [RED, RED, GREEN, GREEN, YELLOW, YELLOW, OFF, GREEN],
    [RED, RED, GREEN, GREEN, YELLOW, YELLOW, OFF, GREEN],
    [RED, RED, GREEN, GREEN, YELLOW, YELLOW, OFF, GREEN],
    [RED, RED, GREEN, GREEN, YELLOW, YELLOW, OFF, GREEN],
    [RED, RED, GREEN, GREEN, YELLOW, YELLOW, OFF, GREEN],
    [RED, RED, GREEN, GREEN, YELLOW, YELLOW, OFF, GREEN]
  ])

  sleep 3

  led.clear
  sleep 3

  led.fill # red by default
  sleep 3

  led.fill GREEN
  sleep 3

  led.fill YELLOW
end
```

### License ###

Copyright (c) 2012, Sungjin Han <meinside@gmail.com>
All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:

 * Redistributions of source code must retain the above copyright notice,
   this list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright
   notice, this list of conditions and the following disclaimer in the
   documentation and/or other materials provided with the distribution.
 * Neither the name of meinside nor the names of its contributors may be
   used to endorse or promote products derived from this software without
   specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.

* * *

