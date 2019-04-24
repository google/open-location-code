require 'test/unit'
require_relative '../lib/plus_codes/open_location_code'

class PlusCodesTest < Test::Unit::TestCase

  def setup
    @test_data_folder_path = File.join(File.dirname(__FILE__), '..', '..', 'test_data')
    @olc = PlusCodes::OpenLocationCode.new
  end

  def test_validity
    read_csv_lines('validityTests.csv').each do |line|
      cols = line.split(',')
      code = cols[0]
      is_valid = cols[1] == 'true'
      is_short = cols[2] == 'true'
      is_full = cols[3] == 'true'
      is_valid_olc = @olc.valid?(code)
      is_short_olc = @olc.short?(code)
      is_full_olc = @olc.full?(code)
      result = is_valid_olc == is_valid && is_short_olc == is_short && is_full_olc == is_full
      assert(result)
    end
  end

  def test_decode
    read_csv_lines('decoding.csv').each do |line|
      cols = line.split(',')
      code_area = @olc.decode(cols[0])
      assert_equal(cols[1].to_i, code_area.code_length, 'Also should be equal')
      assert((code_area.south_latitude - cols[2].to_f).abs < 0.001, 'South')
      assert((code_area.west_longitude - cols[3].to_f).abs < 0.001, 'West')
      assert((code_area.north_latitude - cols[4].to_f).abs < 0.001, 'North')
      assert((code_area.east_longitude - cols[5].to_f).abs < 0.001, 'East')
    end
  end

  def test_encode
    read_csv_lines('encoding.csv').each do |line|
      if line.length == 0
        next
      end
      cols = line.split(',')
      code = @olc.encode(cols[0].to_f, cols[1].to_f, cols[2].to_i)
      assert_equal(cols[3], code)
    end
  end

  def test_shorten
    read_csv_lines('shortCodeTests.csv').each do |line|
      cols = line.split(',')
      code = cols[0]
      lat = cols[1].to_f
      lng = cols[2].to_f
      short_code = cols[3]
      test_type = cols[4]
      if test_type == 'B' || test_type == 'S'
        short = @olc.shorten(code, lat, lng)
        assert_equal(short_code, short)
      end
      if test_type == 'B' || test_type == 'R'
        expanded = @olc.recover_nearest(short_code, lat, lng)
        assert_equal(code, expanded)
      end
    end
    @olc.shorten('9C3W9QCJ+2VX', 60.3701125, 10.202665625)
  end

  def test_longer_encoding_with_special_case
    assert_equal('CFX3X2X2+X2RRRRJ', @olc.encode(90.0, 1.0, 15));
  end

  def test_exceptions
    assert_raise ArgumentError do
      @olc.encode(20, 30, 1)
    end
    assert_raise ArgumentError do
      @olc.encode(20, 30, 9)
    end
    assert_raise ArgumentError do
      @olc.recover_nearest('9C3W9QCJ-2VX', 51.3708675, -1.217765625)
    end
    @olc.recover_nearest('9C3W9QCJ+2VX', 51.3708675, -1.217765625)
    assert_raise ArgumentError do
      @olc.decode('sfdg')
    end
    assert_raise ArgumentError do
      @olc.shorten('9C3W9Q+', 1, 2)
    end
    assert_raise ArgumentError do
      @olc.shorten('9C3W9Q00+', 1, 2)
    end
  end

  def test_valid_with_special_case
    assert(!@olc.valid?('3W00CJJJ+'))
  end

  def read_csv_lines(csv_file)
    f = File.open(File.join(@test_data_folder_path, csv_file), 'r')
    f.each_line.lazy.select { |line| line !~ /^\s*#/ }.map { |line| line.chop }
  end

end
