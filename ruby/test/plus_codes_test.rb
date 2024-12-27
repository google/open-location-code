# frozen_string_literal: true

require 'test/unit'
require_relative '../lib/plus_codes/open_location_code'

class PlusCodesTest < Test::Unit::TestCase
  def setup
    @test_data_folder_path = File.join(
      File.dirname(__FILE__), '..', '..', 'test_data'
    )
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
      result = is_valid_olc == is_valid && is_short_olc == is_short &&
               is_full_olc == is_full
      assert(result)
    end
  end

  def test_decode
    read_csv_lines('decoding.csv').each do |line|
      cols = line.split(',')
      code_area = @olc.decode(cols[0])
      assert_equal(cols[1].to_i, code_area.code_length, 'Also should be equal')
      # Check returned coordinates are within 1e-10 of expected.
      precision = 1e-10
      assert((code_area.south_latitude - cols[2].to_f).abs < precision, 'South')
      assert((code_area.west_longitude - cols[3].to_f).abs < precision, 'West')
      assert((code_area.north_latitude - cols[4].to_f).abs < precision, 'North')
      assert((code_area.east_longitude - cols[5].to_f).abs < precision, 'East')
    end
  end

  def test_encode
    read_csv_lines('encoding.csv').each do |line|
      next if line.empty?

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
      if %w[B S].include?(test_type)
        short = @olc.shorten(code, lat, lng)
        assert_equal(short_code, short)
      end
      if %w[B R].include?(test_type)
        expanded = @olc.recover_nearest(short_code, lat, lng)
        assert_equal(code, expanded)
      end
    end
    @olc.shorten('9C3W9QCJ+2VX', 60.3701125, 10.202665625)
  end

  def test_longer_encoding_with_special_case
    assert_equal('CFX3X2X2+X2RRRRR', @olc.encode(90.0, 1.0, 15))
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

  def test_benchmark
    test_data = []
    100000.times do
      exp = 10.0**rand(10)
      lat = ((rand * 180 - 90) * exp).round / exp
      lng = ((rand * 360 - 180) * exp).round / exp
      len = rand(15)
      len = rand(1..5) * 2 if len <= 10

      test_data.push([lat, lng, len, @olc.encode(lat, lng, len)])
    end
    start_micros = (Time.now.to_f * 1e6).to_i
    test_data.each do |lat, lng, len, _|
      @olc.encode(lat, lng, len)
    end
    duration_micros = (Time.now.to_f * 1e6).to_i - start_micros
    printf('Encode benchmark: ')
    printf("%<total>d usec total, %<loops>d loops, %<percall>f usec per call\n",
           total: duration_micros, loops: test_data.length,
           percall: duration_micros.to_f / test_data.length)

    start_micros = (Time.now.to_f * 1e6).to_i
    test_data.each do |_, _, _, code|
      @olc.decode(code)
    end
    duration_micros = (Time.now.to_f * 1e6).to_i - start_micros
    printf('Decode benchmark: ')
    printf("%<total>d usec total, %<loops>d loops, %<percall>f usec per call\n",
           total: duration_micros, loops: test_data.length,
           percall: duration_micros.to_f / test_data.length)
  end

  def read_csv_lines(csv_file)
    f = File.open(File.join(@test_data_folder_path, csv_file), 'r')
    f.each_line.lazy.reject { |line| line =~ /^\s*#/ }.map(&:chop)
  end
end
