# frozen_string_literal: true

# Plus+Codes is a Ruby implementation of Google Open Location Code (Plus Codes).
#
# @author We-Ming Wu
module PlusCodes
  # The character set used to encode coordinates.
  CODE_ALPHABET = '23456789CFGHJMPQRVWX'

  # The character used to pad a code
  PADDING = '0'

  # A separator used to separate the code into two parts.
  SEPARATOR = '+'

  # The max number of characters can be placed before the separator.
  SEPARATOR_POSITION = 8

  # Minimum number of digits to process in a Plus Code.
  MIN_CODE_LENGTH = 2

  # Maximum number of digits to process in a Plus Code.
  MAX_CODE_LENGTH = 15

  # Maximum code length using lat/lng pair encoding. The area of such a
  # code is approximately 13x13 meters (at the equator), and should be suitable
  # for identifying buildings. This excludes prefix and separator characters.
  PAIR_CODE_LENGTH = 10

  # Inverse of the precision of the pair code section.
  PAIR_CODE_PRECISION = 8000

  # Precision of the latitude grid.
  LAT_GRID_PRECISION = 5**(MAX_CODE_LENGTH - PAIR_CODE_LENGTH)

  # Precision of the longitude grid.
  LNG_GRID_PRECISION = 4**(MAX_CODE_LENGTH - PAIR_CODE_LENGTH)

  # ASCII lookup table.
  DECODE = (CODE_ALPHABET.chars + [PADDING, SEPARATOR]).each_with_object(
    []
  ) do |c, ary|
    ary[c.ord] = CODE_ALPHABET.index(c)
    ary[c.downcase.ord] = CODE_ALPHABET.index(c)
    ary[c.ord] ||= -1
    ary
  end.freeze
end
