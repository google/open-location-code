# PlusCodes

Ruby implementation of Google Open Location Code(Plus+Codes)

The latest source code can be found in this
[PlusCodes Gem Github Repo](https://github.com/wnameless/plus_codes-ruby)

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

1. Fork it ( https://github.com/wnameless/plus_codes-ruby/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
