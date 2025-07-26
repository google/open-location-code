defmodule OpenLocationCode do
  @moduledoc """
  Convert locations to and from Open Location Code (Plus Code).

  Plus Codes are short, 10-11 character codes that can be used instead
  of street addresses. The codes can be generated and decoded offline, and use
  a reduced character set that minimises the chance of codes including words.

  Codes are able to be shortened relative to a nearby location. This means that
  in many cases, only four to seven characters of the code are needed.
  To recover the original code, the same location is not required, as long as
  a nearby location is provided.

  Codes represent rectangular areas rather than points, and the longer the
  code, the smaller the area. A 10 character code represents a 13.5x13.5
  meter area (at the equator). An 11 character code represents approximately
  a 2.8x3.5 meter area.

  ## Examples

      # Encode a location, default accuracy:
      OpenLocationCode.encode(47.365590, 8.524997)
      #=> {:ok, "8FVC9G8F+6X"}

      # Encode a location using one stage of additional refinement:
      OpenLocationCode.encode(47.365590, 8.524997, 11)
      #=> {:ok, "8FVC9G8F+6XQ"}

      # Decode a full code:
      {:ok, code_area} = OpenLocationCode.decode("8FVC9G8F+6X")

      # Attempt to trim the first characters from a code:
      OpenLocationCode.shorten("8FVC9G8F+6X", 47.5, 8.5)
      #=> {:ok, "9G8F+6X"}

      # Recover the full code from a short code:
      OpenLocationCode.recover_nearest("9G8F+6X", 47.4, 8.6)
      #=> {:ok, "8FVC9G8F+6X"}

      OpenLocationCode.recover_nearest("8F+6X", 47.4, 8.6)
      #=> {:ok, "8FVC9G8F+6X"}
  """

  # A separator used to break the code into two parts to aid memorability.
  @separator "+"

  # The number of characters to place before the separator.
  @separator_position 8

  # The character used to pad codes.
  @padding_character "0"

  # The character set used to encode the values.
  @code_alphabet "23456789CFGHJMPQRVWX"

  # The base to use to convert numbers to/from.
  @encoding_base String.length(@code_alphabet)

  # The maximum value for latitude in degrees.
  @latitude_max 90

  # The maximum value for longitude in degrees.
  @longitude_max 180

  # The min number of digits to process in a Plus Code.
  @min_digit_count 2

  # The max number of digits to process in a Plus Code.
  @max_digit_count 15

  # Maximum code length using lat/lng pair encoding. The area of such a
  # code is approximately 13x13 meters (at the equator), and should be suitable
  # for identifying buildings. This excludes prefix and separator characters.
  @pair_code_length 10

  # First place value of the pairs (if the last pair value is 1).
  @pair_first_place_value :math.pow(@encoding_base, @pair_code_length / 2 - 1) |> trunc()

  # Inverse of the precision of the pair section of the code.
  @pair_precision :math.pow(@encoding_base, 3) |> trunc()

  # The resolution values in degrees for each position in the lat/lng pair
  # encoding. These give the place value of each position, and therefore the
  # dimensions of the resulting area.
  @pair_resolutions [20.0, 1.0, 0.05, 0.0025, 0.000125]

  # Number of digits in the grid precision part of the code.
  @grid_code_length @max_digit_count - @pair_code_length

  # Number of columns in the grid refinement method.
  @grid_columns 4

  # Number of rows in the grid refinement method.
  @grid_rows 5

  # First place value of the latitude grid (if the last place is 1).
  @grid_lat_first_place_value :math.pow(@grid_rows, @grid_code_length - 1) |> trunc()

  # First place value of the longitude grid (if the last place is 1).
  @grid_lng_first_place_value :math.pow(@grid_columns, @grid_code_length - 1) |> trunc()

  # Multiply latitude by this much to make it a multiple of the finest precision.
  @final_lat_precision @pair_precision *
                         (:math.pow(@grid_rows, @max_digit_count - @pair_code_length) |> trunc())

  # Multiply longitude by this much to make it a multiple of the finest precision.
  @final_lng_precision @pair_precision *
                         (:math.pow(@grid_columns, @max_digit_count - @pair_code_length)
                          |> trunc())

  # Minimum length of a code that can be shortened.
  @min_trimmable_code_len 6

  defmodule CodeArea do
    @moduledoc """
    Coordinates of a decoded Open Location Code.

    The coordinates include the latitude and longitude of the lower left and
    upper right corners and the center of the bounding box for the area the
    code represents.
    """
    defstruct [
      :latitude_lo,
      :longitude_lo,
      :latitude_hi,
      :longitude_hi,
      :latitude_center,
      :longitude_center,
      :code_length
    ]

    @type t :: %__MODULE__{
            latitude_lo: float(),
            longitude_lo: float(),
            latitude_hi: float(),
            longitude_hi: float(),
            latitude_center: float(),
            longitude_center: float(),
            code_length: integer()
          }

    def new(latitude_lo, longitude_lo, latitude_hi, longitude_hi, code_length) do
      latitude_center = min(latitude_lo + (latitude_hi - latitude_lo) / 2, 90.0)
      longitude_center = min(longitude_lo + (longitude_hi - longitude_lo) / 2, 180.0)

      %__MODULE__{
        latitude_lo: latitude_lo,
        longitude_lo: longitude_lo,
        latitude_hi: latitude_hi,
        longitude_hi: longitude_hi,
        latitude_center: latitude_center,
        longitude_center: longitude_center,
        code_length: code_length
      }
    end
  end

  @doc """
  Determines if a code is valid.

  To be valid, all characters must be from the Open Location Code character
  set with at most one separator. The separator can be in any even-numbered
  position up to the eighth digit.

  ## Examples

      iex> OpenLocationCode.valid?("8FVC9G8F+6X")
      true

      iex> OpenLocationCode.valid?("8FVC9G8F+6XQ")
      true

      iex> OpenLocationCode.valid?("invalid")
      false

      iex> OpenLocationCode.valid?("8FVC9G8F6X")  # missing separator
      false
  """
  def valid?(code) when is_binary(code) do
    # The separator is required.
    case String.split(code, @separator) do
      # No separator
      [_] ->
        false

      ["", ""] ->
        false

      [prefix, suffix] ->
        # Check separator position
        sep_pos = String.length(prefix)

        if sep_pos > @separator_position or rem(sep_pos, 2) == 1 do
          false
        else
          validate_padding_and_characters(code, prefix, suffix, sep_pos)
        end

      # Multiple separators
      _ ->
        false
    end
  end

  def valid?(_), do: false

  defp validate_padding_and_characters(code, prefix, suffix, sep_pos) do
    # Check for padding
    case String.contains?(prefix, @padding_character) do
      true ->
        # Short codes cannot have padding
        if sep_pos < @separator_position do
          false
        else
          validate_padding(code, prefix)
        end

      false ->
        validate_characters_and_suffix(code, suffix)
    end
  end

  defp validate_padding(code, prefix) do
    # Not allowed to start with padding
    if String.starts_with?(prefix, @padding_character) do
      false
    else
      # Find padding section
      pad_start = first_index(prefix, @padding_character)
      pad_end = last_index(prefix, @padding_character)
      padding_section = String.slice(prefix, pad_start..pad_end)

      # Must have even length and be all padding characters
      if rem(String.length(padding_section), 2) == 1 or
           not String.match?(padding_section, ~r/^#{@padding_character}+$/) do
        false
      else
        # Must end with separator if long enough
        String.ends_with?(code, @separator) and validate_all_characters(code)
      end
    end
  end

  defp validate_characters_and_suffix(code, suffix) do
    # If there are characters after the separator, make sure there isn't just one
    if String.length(suffix) == 1 do
      false
    else
      validate_all_characters(code)
    end
  end

  defp validate_all_characters(code) do
    valid_chars = @code_alphabet <> @separator <> @padding_character

    String.graphemes(code)
    |> Enum.all?(fn char ->
      String.contains?(valid_chars, String.upcase(char))
    end)
  end

  @doc """
  Determines if a code is a valid short code.

  A short Open Location Code is a sequence created by removing four or more
  digits from an Open Location Code. It must include a separator character.

  ## Examples

      iex> OpenLocationCode.short?("9G8F+6X")
      true

      iex> OpenLocationCode.short?("8F+6X")
      true

      iex> OpenLocationCode.short?("8FVC9G8F+6X")  # full code
      false

      iex> OpenLocationCode.short?("invalid")
      false
  """
  def short?(code) do
    if valid?(code) do
      [prefix, _] = String.split(code, @separator)
      String.length(prefix) < @separator_position
    else
      false
    end
  end

  @doc """
  Determines if a code is a valid full Open Location Code.

  Not all possible combinations of Open Location Code characters decode to
  valid latitude and longitude values. This checks that a code is valid
  and also that the latitude and longitude values are legal.

  ## Examples

      iex> OpenLocationCode.full?("8FVC9G8F+6X")
      true

      iex> OpenLocationCode.full?("9G8F+6X")  # short code
      false

      iex> OpenLocationCode.full?("invalid")
      false
  """
  def full?(code) do
    if valid?(code) and not short?(code) do
      # Work out what the first latitude character indicates for latitude
      first_lat_char = String.upcase(code) |> String.at(0)
      first_lat_value = char_to_index(first_lat_char) * @encoding_base

      if first_lat_value >= @latitude_max * 2 do
        false
      else
        if String.length(code) > 1 do
          # Work out what the first longitude character indicates for longitude
          first_lng_char = String.upcase(code) |> String.at(1)
          first_lng_value = char_to_index(first_lng_char) * @encoding_base
          first_lng_value < @longitude_max * 2
        else
          true
        end
      end
    else
      false
    end
  end

  @doc """
  Encode a location into an Open Location Code.

  Produces a code of the specified length, or the default length if no length
  is provided. The length determines the accuracy of the code. The default
  length is 10 characters.

  ## Parameters

  - `latitude` - The latitude in degrees (must be between -90 and 90)
  - `longitude` - The longitude in degrees (must be between -180 and 180)
  - `code_length` - The desired length of the code (default: 10, max: 15)

  ## Examples

      iex> OpenLocationCode.encode(47.365590, 8.524997)
      {:ok, "8FVC9G8F+6X"}

      iex> OpenLocationCode.encode(47.365590, 8.524997, 11)
      {:ok, "8FVC9G8F+6XQ"}
  """
  def encode(latitude, longitude, code_length \\ @pair_code_length) do
    {:ok, {lat_int, lng_int}} = location_to_integers(latitude, longitude)
    encode_integers(lat_int, lng_int, code_length)
  end

  @doc """
  Convert location in degrees into integer representations.

  This is an internal helper function that converts floating-point coordinates
  into integer values for processing.

  ## Examples

      iex> OpenLocationCode.location_to_integers(47.365590, 8.524997)
      {:ok, {3434139750, 1544396775}}
  """
  def location_to_integers(latitude, longitude) do
    lat_val = trunc(:math.floor(latitude * @final_lat_precision))
    lat_val = lat_val + @latitude_max * @final_lat_precision

    lat_val =
      cond do
        lat_val < 0 ->
          0

        lat_val >= 2 * @latitude_max * @final_lat_precision ->
          2 * @latitude_max * @final_lat_precision - 1

        true ->
          lat_val
      end

    lng_val = trunc(:math.floor(longitude * @final_lng_precision))
    lng_val = lng_val + @longitude_max * @final_lng_precision

    lng_val =
      cond do
        lng_val < 0 or lng_val >= 2 * @longitude_max * @final_lng_precision ->
          modulo(lng_val, 2 * @longitude_max * @final_lng_precision)

        true ->
          lng_val
      end

    {:ok, {lat_val, lng_val}}
  end

  defp modulo(a, b) when b > 0 do
    result = rem(a, b)
    if result < 0, do: result + b, else: result
  end

  @doc """
  Encode a location using integer values into a code.

  This function takes pre-computed integer representations of latitude and
  longitude coordinates and generates an Open Location Code.

  ## Examples

      iex> OpenLocationCode.encode_integers(4736559000, 852499700, 10)
      {:ok, "F7F6F367+WX"}
  """
  def encode_integers(lat_val, lng_val, code_length) do
    cond do
      (code_length < @pair_code_length and rem(code_length, 2) == 1) or
          code_length < @min_digit_count ->
        {:error, :invalid_open_location_code_length}

      true ->
        code_length = min(code_length, @max_digit_count)
        code = ""

        # Compute the grid part of the code if necessary
        {code, lat_val, lng_val} =
          if code_length > @pair_code_length do
            compute_grid_part("", lat_val, lng_val, 0, @max_digit_count - @pair_code_length)
          else
            lat_val = div(lat_val, trunc(:math.pow(@grid_rows, @grid_code_length)))
            lng_val = div(lng_val, trunc(:math.pow(@grid_columns, @grid_code_length)))
            {code, lat_val, lng_val}
          end

        # Compute the pair section of the code
        code = compute_pair_section(code, lat_val, lng_val, 0, div(@pair_code_length, 2))

        # Add the separator character
        {prefix, suffix} = String.split_at(code, @separator_position)
        code = prefix <> @separator <> suffix

        # Return the requested section or pad if necessary
        if code_length >= @separator_position do
          {:ok, String.slice(code, 0, code_length + 1)}
        else
          padding = String.duplicate(@padding_character, @separator_position - code_length)
          {:ok, String.slice(code, 0, code_length) <> padding <> @separator}
        end
    end
  end

  defp compute_grid_part(code, lat_val, lng_val, i, max_i) when i < max_i do
    lat_digit = rem(lat_val, @grid_rows)
    lng_digit = rem(lng_val, @grid_columns)
    ndx = lat_digit * @grid_columns + lng_digit
    char = String.at(@code_alphabet, ndx)
    new_code = char <> code
    new_lat_val = div(lat_val, @grid_rows)
    new_lng_val = div(lng_val, @grid_columns)
    compute_grid_part(new_code, new_lat_val, new_lng_val, i + 1, max_i)
  end

  defp compute_grid_part(code, lat_val, lng_val, _i, _max_i), do: {code, lat_val, lng_val}

  defp compute_pair_section(code, lat_val, lng_val, i, max_i) when i < max_i do
    lng_char = String.at(@code_alphabet, rem(lng_val, @encoding_base))
    lat_char = String.at(@code_alphabet, rem(lat_val, @encoding_base))
    new_code = lat_char <> lng_char <> code
    new_lat_val = div(lat_val, @encoding_base)
    new_lng_val = div(lng_val, @encoding_base)
    compute_pair_section(new_code, new_lat_val, new_lng_val, i + 1, max_i)
  end

  defp compute_pair_section(code, _lat_val, _lng_val, _i, _max_i), do: code

  @doc """
  Decodes an Open Location Code into location coordinates.

  Returns a tuple with `:ok` and a `CodeArea` struct that includes the
  coordinates of the bounding box - the lower left, center and upper right.
  Returns an error tuple if the code is invalid or not a full code.

  ## Examples

      iex> OpenLocationCode.decode("8FVC9G8F+6X")
      {:ok,
       %OpenLocationCode.CodeArea{
         latitude_lo: 47.3655,
         longitude_lo: 8.524875,
         latitude_hi: 47.36562499999999,
         longitude_hi: 8.525,
         latitude_center: 47.365562499999996,
         longitude_center: 8.5249375,
         code_length: 10
       }}

      iex> OpenLocationCode.decode("invalid")
      {:error, :invalid_code}

      iex> OpenLocationCode.decode("9G8F+6X")  # short code
      {:error, :full_code_expected}
  """
  def decode(code) when is_binary(code) do
    cond do
      not valid?(code) ->
        {:error, :invalid_code}

      not full?(code) ->
        {:error, :full_code_expected}

      true ->
        # Strip out separator and padding characters, convert to upper case
        clean_code =
          code
          |> String.replace(~r/[\+0]/, "")
          |> String.upcase()
          |> String.slice(0, @max_digit_count)

        # Initialize values for each section
        normal_lat = -@latitude_max * @pair_precision
        normal_lng = -@longitude_max * @pair_precision
        grid_lat = 0
        grid_lng = 0

        # How many digits do we have to process?
        digits = min(String.length(clean_code), @pair_code_length)

        # Decode the paired digits
        {normal_lat, normal_lng, pv} = decode_pairs(clean_code, normal_lat, normal_lng, digits)

        # Convert the place value to a float in degrees
        lat_precision = pv / @pair_precision
        lng_precision = pv / @pair_precision

        # Process any extra precision digits
        {lat_precision, lng_precision, grid_lat, grid_lng} =
          if String.length(clean_code) > @pair_code_length do
            decode_grid_section(clean_code, grid_lat, grid_lng)
          else
            {lat_precision, lng_precision, grid_lat, grid_lng}
          end

        # Merge the values from the normal and extra precision parts
        lat = normal_lat / @pair_precision + grid_lat / @final_lat_precision
        lng = normal_lng / @pair_precision + grid_lng / @final_lng_precision

        # Round to reduce floating point precision errors
        code_area =
          CodeArea.new(
            Float.round(lat, 14),
            Float.round(lng, 14),
            Float.round(lat + lat_precision, 14),
            Float.round(lng + lng_precision, 14),
            min(String.length(clean_code), @max_digit_count)
          )

        {:ok, code_area}
    end
  end

  def decode(_), do: {:error, :invalid_code}

  defp decode_pairs(code, normal_lat, normal_lng, digits) do
    pv = @pair_first_place_value
    decode_pairs_loop(code, normal_lat, normal_lng, pv, 0, digits)
  end

  defp decode_pairs_loop(_code, normal_lat, normal_lng, pv, i, digits) when i >= digits do
    {normal_lat, normal_lng, pv}
  end

  defp decode_pairs_loop(code, normal_lat, normal_lng, pv, i, digits) do
    lat_char = String.at(code, i)
    lng_char = String.at(code, i + 1)

    lat_val = char_to_index(lat_char)
    lng_val = char_to_index(lng_char)

    new_normal_lat = normal_lat + lat_val * pv
    new_normal_lng = normal_lng + lng_val * pv

    new_pv = if i < digits - 2, do: div(pv, @encoding_base), else: pv

    decode_pairs_loop(code, new_normal_lat, new_normal_lng, new_pv, i + 2, digits)
  end

  defp decode_grid_section(code, grid_lat, grid_lng) do
    rowpv = @grid_lat_first_place_value
    colpv = @grid_lng_first_place_value
    digits = min(String.length(code), @max_digit_count)

    {grid_lat, grid_lng, rowpv, colpv} =
      decode_grid_loop(code, grid_lat, grid_lng, rowpv, colpv, @pair_code_length, digits)

    lat_precision = rowpv / @final_lat_precision
    lng_precision = colpv / @final_lng_precision

    {lat_precision, lng_precision, grid_lat, grid_lng}
  end

  defp decode_grid_loop(_code, grid_lat, grid_lng, rowpv, colpv, i, digits) when i >= digits do
    {grid_lat, grid_lng, rowpv, colpv}
  end

  defp decode_grid_loop(code, grid_lat, grid_lng, rowpv, colpv, i, digits) do
    digit_char = String.at(code, i)
    digit_val = char_to_index(digit_char)

    row = div(digit_val, @grid_columns)
    col = rem(digit_val, @grid_columns)

    new_grid_lat = grid_lat + row * rowpv
    new_grid_lng = grid_lng + col * colpv

    {new_rowpv, new_colpv} =
      if i < digits - 1 do
        {div(rowpv, @grid_rows), div(colpv, @grid_columns)}
      else
        {rowpv, colpv}
      end

    decode_grid_loop(code, new_grid_lat, new_grid_lng, new_rowpv, new_colpv, i + 1, digits)
  end

  @doc """
  Recover the nearest matching full code to a specified location.

  Given a short code of between four and seven characters, this recovers
  the nearest matching full code to the specified location.

  If a full code is provided, it returns the code in proper capitalization.

  ## Parameters

  - `code` - A short Open Location Code (or full code)
  - `reference_latitude` - Reference latitude in degrees
  - `reference_longitude` - Reference longitude in degrees

  ## Examples

      iex> OpenLocationCode.recover_nearest("9G8F+6X", 47.4, 8.6)
      {:ok, "8FVC9G8F+6X"}

      iex> OpenLocationCode.recover_nearest("8F+6X", 47.4, 8.6)
      {:ok, "8FVCCJ8F+6X"}

      # Full codes are returned as-is (but uppercased)
      iex> OpenLocationCode.recover_nearest("8fvc9g8f+6x", 47.4, 8.6)
      {:ok, "8FVC9G8F+6X"}
  """
  def recover_nearest(code, reference_latitude, reference_longitude) do
    # If code is a valid full code, return it properly capitalized
    if full?(code) do
      {:ok, String.upcase(code)}
    else
      # Ensure that latitude and longitude are valid
      reference_latitude = clip_latitude(reference_latitude)
      reference_longitude = normalize_longitude(reference_longitude)

      # Clean up the passed code
      clean_code = String.upcase(code)

      # Compute the number of digits we need to recover
      [prefix, _] = String.split(clean_code, @separator, parts: 2)
      padding_length = @separator_position - String.length(prefix)

      # The resolution of the padded area in degrees
      resolution = :math.pow(20, 2 - padding_length / 2)
      half_resolution = resolution / 2.0

      # Use the reference location to pad the supplied short code and decode it
      {:ok, reference_code} = encode(reference_latitude, reference_longitude)
      padded_code = String.slice(reference_code, 0, padding_length) <> clean_code

      {:ok, code_area} = decode(padded_code)

      # Adjust latitude if necessary
      latitude_center =
        cond do
          reference_latitude + half_resolution < code_area.latitude_center and
              code_area.latitude_center - resolution >= -@latitude_max ->
            code_area.latitude_center - resolution

          reference_latitude - half_resolution > code_area.latitude_center and
              code_area.latitude_center + resolution <= @latitude_max ->
            code_area.latitude_center + resolution

          true ->
            code_area.latitude_center
        end

      # Adjust longitude if necessary
      longitude_center =
        cond do
          reference_longitude + half_resolution < code_area.longitude_center ->
            code_area.longitude_center - resolution

          reference_longitude - half_resolution > code_area.longitude_center ->
            code_area.longitude_center + resolution

          true ->
            code_area.longitude_center
        end

      encode(latitude_center, longitude_center, code_area.code_length)
    end
  end

  @doc """
  Remove characters from the start of an Open Location Code.

  This uses a reference location to determine how many initial characters
  can be removed from the OLC code. The closer the reference location is
  to the code's center, the more characters can be removed.

  Returns an error if the code cannot be shortened (e.g., if it's not a full
  code, contains padding, or is too short).

  ## Parameters

  - `code` - A full Open Location Code
  - `latitude` - Reference latitude in degrees
  - `longitude` - Reference longitude in degrees

  ## Examples

      iex> OpenLocationCode.shorten("8FVC9G8F+6X", 47.5, 8.5)
      {:ok, "9G8F+6X"}

      # Error cases
      iex> OpenLocationCode.shorten("9G8F+6X", 47.5, 8.5)  # short code
      {:error, :full_code_expected}

      iex> OpenLocationCode.shorten("8FVC00+", 47.5, 8.5)  # padded code
      {:error, :cannot_shorten_padded_codes}
  """
  def shorten(code, latitude, longitude) do
    cond do
      not full?(code) ->
        {:error, :full_code_expected}

      String.contains?(code, @padding_character) ->
        {:error, :cannot_shorten_padded_codes}

      true ->
        clean_code = String.upcase(code)
        {:ok, code_area} = decode(clean_code)

        if code_area.code_length < @min_trimmable_code_len do
          {:error, :code_length_too_small}
        else
          # Ensure that latitude and longitude are valid
          latitude = clip_latitude(latitude)
          longitude = normalize_longitude(longitude)

          # How close are the latitude and longitude to the code center
          code_range =
            max(
              abs(code_area.latitude_center - latitude),
              abs(code_area.longitude_center - longitude)
            )

          # Check if we can shorten at different resolutions
          {:ok, shorten_at_resolution(clean_code, code_range, length(@pair_resolutions) - 2)}
        end
    end
  end

  defp shorten_at_resolution(code, code_range, i) do
    resolution = Enum.at(@pair_resolutions, i)

    if code_range < resolution * 0.3 do
      # Trim it
      String.slice(code, ((i + 1) * 2)..-1//1)
    else
      shorten_at_resolution(code, code_range, i - 1)
    end
  end

  @doc """
  Clip a latitude into the range -90 to 90.
  """
  def clip_latitude(latitude) do
    min(90, max(-90, latitude))
  end

  @doc """
  Normalize a longitude into the range -180 to 180, not including 180.
  """
  def normalize_longitude(longitude) do
    longitude
    |> normalize_longitude_positive()
    |> normalize_longitude_negative()
  end

  defp normalize_longitude_positive(longitude) when longitude >= 180 do
    normalize_longitude_positive(longitude - 360)
  end

  defp normalize_longitude_positive(longitude), do: longitude

  defp normalize_longitude_negative(longitude) when longitude < -180 do
    normalize_longitude_negative(longitude + 360)
  end

  defp normalize_longitude_negative(longitude), do: longitude

  # Helper function to find character index in alphabet
  defp char_to_index(char) do
    first_index(@code_alphabet, char)
  end

  defp first_index(string, char) do
    {index, _} = :binary.match(string, char)
    index
  end

  defp last_index(string, char) do
    index =
      string
      |> String.reverse()
      |> first_index(char)

    String.length(string) - index - 1
  end
end
