# Plus Codes

Ruby implementation of Open Location Code library.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

Your code must pass tests, and must be formatted with
[rubocop](https://github.com/rubocop-hq/rubocop). This will check all the ruby
files and print a list of corrections you need to make - it will not format your
file automatically.

```
gem install rubocop
rubocop --config rubocop.yml
```

If you can't run it yourself, it is run as part of the TravisCI tests.


### Testing

```
gem install test-unit
ruby test/plus_codes_test.rb
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'plus_codes'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install plus_codes

## Usage

```ruby
require 'plus_codes/open_location_code'

olc = PlusCodes::OpenLocationCode.new

# Encodes the latitude and longitude into a Plus+Codes
code = olc.encode(47.0000625,8.0000625)
# => "8FVC2222+22"

# Encodes any latitude and longitude into a Plus+Codes with preferred length
code = olc.encode(47.0000625,8.0000625, 16)
# => "8FVC2222+22GCCCCC"

# Decodes a Plus+Codes back into coordinates
code_area = olc.decode(code)
puts code_area
# => lat_lo: 47.000062496 long_lo: 8.0000625 lat_hi: 47.000062504 long_hi: 8.000062530517578 code_len: 16

# Checks if a Plus+Codes is valid or not
olc.valid?(code)
# => true

# Checks if a Plus+Codes is full or not
olc.full?(code)
# => true

# Checks if a Plus+Codes is short or not
olc.short?(code)
# => false

# Shorten a Plus+Codes as possible by given reference latitude and longitude
olc.shorten('9C3W9QCJ+2VX', 51.3708675, -1.217765625)
# => "CJ+2VX"

# Extends a Plus+Codes by given reference latitude and longitude
olc.recover_nearest('CJ+2VX', 51.3708675, -1.217765625)
# => "9C3W9QCJ+2VX"
```

## Contributing
