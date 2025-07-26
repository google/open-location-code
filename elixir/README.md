# OpenLocationCode

An Elixir implementation of Google's Open Location Code (Plus Code) system for encoding and decoding geographic locations.

Plus Codes are short, 10-11 character codes that can be used instead of street addresses. The codes can be generated and decoded offline, and use a reduced character set that minimizes the chance of codes including words.

## Features

- **Encode** latitude/longitude coordinates to Plus Codes
- **Decode** Plus Codes back to coordinate areas
- **Shorten** codes relative to a reference location
- **Recover** full codes from shortened versions
- **Validate** code format and structure
- **Offline operation** - no internet connection required

## Installation

Add `olc` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:olc, "~> 0.1.0"}
  ]
end
```

## Quick Start

```elixir
# Encode a location (Zurich, Switzerland)
{:ok, code} = OpenLocationCode.encode(47.365590, 8.524997)
# => {:ok, "8FVC9G8F+6X"}

# Decode a Plus Code
{:ok, area} = OpenLocationCode.decode("8FVC9G8F+6X")
# => {:ok, %OpenLocationCode.CodeArea{...}}

# Access the decoded coordinates
area.latitude_center   # => 47.36558750000001
area.longitude_center  # => 8.524997500000002
```

## Usage

### Encoding Coordinates

Convert latitude and longitude to a Plus Code:

```elixir
# Default precision (10 characters)
{:ok, code} = OpenLocationCode.encode(47.365590, 8.524997)
# => {:ok, "8FVC9G8F+6X"}

# Higher precision (11 characters)
{:ok, code} = OpenLocationCode.encode(47.365590, 8.524997, 11)
# => {:ok, "8FVC9G8F+6XQ"}

# Lower precision (6 characters)
{:ok, code} = OpenLocationCode.encode(47.365590, 8.524997, 6)
# => {:ok, "8FVC00+"}
```

### Decoding Plus Codes

Convert Plus Codes back to geographic areas:

```elixir
{:ok, area} = OpenLocationCode.decode("8FVC9G8F+6X")

# Access bounding box coordinates
area.latitude_lo       # => 47.365575
area.longitude_lo      # => 8.524975
area.latitude_hi       # => 47.3656
area.longitude_hi      # => 8.52502
area.latitude_center   # => 47.36558750000001
area.longitude_center  # => 8.524997500000002
area.code_length       # => 10
```

### Shortening Codes

Remove characters from the start of a code using a reference location:

```elixir
# The closer the reference location, the more characters can be removed
{:ok, short_code} = OpenLocationCode.shorten("8FVC9G8F+6X", 47.5, 8.5)
# => {:ok, "9G8F+6X"}

# Very close reference location allows more shortening
{:ok, shorter_code} = OpenLocationCode.shorten("8FVC9G8F+6X", 47.365590, 8.524997)
# => {:ok, "8F+6X"}
```

### Recovering Full Codes

Expand shortened codes back to full codes using a reference location:

```elixir
{:ok, full_code} = OpenLocationCode.recover_nearest("9G8F+6X", 47.4, 8.6)
# => {:ok, "8FVC9G8F+6X"}

{:ok, full_code} = OpenLocationCode.recover_nearest("8F+6X", 47.4, 8.6)
# => {:ok, "8FVC9G8F+6X"}
```

### Validation

Check if codes are valid, short, or full:

```elixir
OpenLocationCode.valid?("8FVC9G8F+6X")      # => true
OpenLocationCode.valid?("invalid")          # => false

OpenLocationCode.short?("9G8F+6X")          # => true
OpenLocationCode.short?("8FVC9G8F+6X")      # => false

OpenLocationCode.full?("8FVC9G8F+6X")       # => true
OpenLocationCode.full?("9G8F+6X")           # => false
```

## Code Areas and Precision

Plus Codes represent rectangular areas, not exact points. The length of the code determines the precision:

| Code Length | Grid Size (at equator) | Example Use Case |
|-------------|------------------------|------------------|
| 6 characters | ~13.9 km × 13.9 km | City/town level |
| 8 characters | ~690 m × 690 m | Neighborhood |
| 10 characters | ~13.5 m × 13.5 m | Building identification |
| 11 characters | ~2.8 m × 3.5 m | Precise locations |

## API Reference

### Core Functions

- `encode(latitude, longitude, code_length \\ 10)` - Encode coordinates to Plus Code
- `decode(code)` - Decode Plus Code to coordinate area
- `shorten(code, latitude, longitude)` - Shorten code relative to location  
- `recover_nearest(code, latitude, longitude)` - Recover full code from short code

### Validation Functions

- `valid?(code)` - Check if code format is valid
- `short?(code)` - Check if code is a short code
- `full?(code)` - Check if code is a full code

### Utility Functions

- `clip_latitude(latitude)` - Clip latitude to valid range (-90 to 90)
- `normalize_longitude(longitude)` - Normalize longitude to valid range (-180 to 180)

## Error Handling

Functions return tagged tuples for clear error handling:

```elixir
case OpenLocationCode.decode("invalid") do
  {:ok, area} ->
    # Process the decoded area
    IO.puts("Center: #{area.latitude_center}, #{area.longitude_center}")

  {:error, :invalid_code} ->
    IO.puts("Invalid code format")

  {:error, :full_code_expected} ->
    IO.puts("Expected a full code, got a short code")
end
```

### Common Error Types

- `:invalid_code` - Code format is invalid
- `:full_code_expected` - Operation requires a full code
- `:cannot_shorten_padded_codes` - Cannot shorten codes with padding
- `:code_length_too_small` - Code too short to be shortened further
- `:invalid_open_location_code_length` - Invalid code length specified

## Use Cases

### Address Replacement
Plus Codes can serve as addresses in areas without traditional addressing systems:

```elixir
# Generate a Plus Code for a location
{:ok, address_code} = OpenLocationCode.encode(-1.2921, 36.8219)  # Nairobi
# Share "6GCRMRFC+" as an address
```

### Location Sharing
Share precise locations without revealing exact coordinates:

```elixir
# Share a shortened code relative to a known landmark
{:ok, short_code} = OpenLocationCode.shorten(full_code, landmark_lat, landmark_lng)
# Share the shorter, more memorable code
```

### Emergency Services
Provide precise location information in areas with poor addressing:

```elixir
# Generate high-precision code for emergency response
{:ok, precise_code} = OpenLocationCode.encode(lat, lng, 11)
# 11-character code provides ~3m precision
```

## Technical Details

- **Character Set**: Uses 20 characters (23456789CFGHJMPQRVWX) avoiding vowels and similar-looking characters
- **Grid System**: Based on a hierarchical grid system with base-20 encoding
- **Precision**: Each additional character increases precision by factor of 20
- **Offline**: All operations work without internet connectivity
- **Global**: Works anywhere on Earth

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes with tests
4. Run the test suite (`mix test`)
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## References

- [Open Location Code Specification](https://github.com/google/open-location-code/blob/main/Documentation/Specification/specification.md)
- [Plus Codes Official Site](https://plus.codes/)
- [Google's Open Location Code Repository](https://github.com/google/open-location-code)

## Acknowledgments

- Based on Google's Open Location Code specification
- Inspired by implementations in other programming languages
