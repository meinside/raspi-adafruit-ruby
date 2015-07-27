Gem::Specification.new do |s|
  s.name        = 'raspi-adafruit-ruby'
  s.version     = '0.0.2'
  s.summary     = "Gem version of https://github.com/meinside/raspi-adafruit-ruby"
  s.description = "Small ruby code snippets for Raspberry Pi peripherals from Adafruit"
  s.authors     = ["Sungjin Han", "Alex Speller"]
  s.email       = 'meinside@gmail.com'
  s.files       = Dir.glob('lib/**/*')
  s.homepage    = 'https://github.com/alexspeller/raspi-adafruit-ruby'
  s.license       = 'MIT'
  s.add_runtime_dependency 'i2c', '>= 0.2.22'
end
