# Plus+Codes is a Ruby implementation of Google Open Location Code(Plus+Codes).
#
# @author We-Ming Wu
module PlusCodes

  # A separator used to separate the code into two parts.
  SEPARATOR = '+'.freeze

  # The max number of characters can be placed before the separator.
  SEPARATOR_POSITION = 8

  # The character used to pad a code
  PADDING = '0'.freeze

  # The character set used to encode coordinates.
  CODE_ALPHABET = '23456789CFGHJMPQRVWX'.freeze

  # ASCII lookup table.
  DECODE = (CODE_ALPHABET.chars + [PADDING, SEPARATOR]).reduce([]) do |ary, c|
    ary[c.ord] = CODE_ALPHABET.index(c)
    ary[c.downcase.ord] = CODE_ALPHABET.index(c)
    ary[c.ord] ||= -1
    ary
  end.freeze

end
