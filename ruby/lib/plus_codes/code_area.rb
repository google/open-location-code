# frozen_string_literal: true

module PlusCodes
  # [CodeArea] contains coordinates of a decoded Open Location Code(Plus+Codes).
  # The coordinates include the latitude and longitude of the lower left and
  # upper right corners and the center of the bounding box for the area the
  # code represents.
  #
  # @author We-Ming Wu
  class CodeArea
    attr_accessor :south_latitude, :west_longitude, :latitude_height,
                  :longitude_width, :latitude_center, :longitude_center,
                  :code_length

    # Creates a [CodeArea].
    #
    # @param south_latitude [Numeric] the latitude of the SW corner in degrees
    # @param west_longitude [Numeric] the longitude of the SW corner in degrees
    # @param latitude_height [Numeric] the height from the SW corner in degrees
    # @param longitude_width [Numeric] the width from the SW corner in degrees
    # @param code_length [Numeric] the number of significant digits in the code
    # @return [CodeArea] a code area which contains the coordinates
    def initialize(south_latitude, west_longitude, latitude_height,
                   longitude_width, code_length)
      @south_latitude = south_latitude
      @west_longitude = west_longitude
      @latitude_height = latitude_height
      @longitude_width = longitude_width
      @code_length = code_length
      @latitude_center = south_latitude + latitude_height / 2.0
      @longitude_center = west_longitude + longitude_width / 2.0
    end

    def north_latitude
      @south_latitude + @latitude_height
    end

    def east_longitude
      @west_longitude + @longitude_width
    end
  end
end
