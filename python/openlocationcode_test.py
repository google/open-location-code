#  -*- coding: utf-8 -*-

# pylint: disable=redefined-builtin
from io import open
import unittest
import openlocationcode as olc

# Location of test data files.
_TEST_DATA = 'test_data'


class TestValidity(unittest.TestCase):

  def setUp(self):
    self.testdata = []
    headermap = {0: 'code', 1: 'isValid', 2: 'isShort', 3: 'isFull'}
    tests_fn = _TEST_DATA + '/validityTests.csv'
    with open(tests_fn, mode='r', encoding='utf-8') as fin:
      for line in fin:
        if line.startswith('#'):
          continue
        td = line.strip().split(',')
        assert len(td) == len(
            headermap), 'Wrong format of testing data: {0}'.format(line)
        # all values should be booleans except the code
        for i in range(1, len(headermap)):
          td[i] = (td[i] == 'true')
        self.testdata.append({headermap[i]: v for i, v in enumerate(td)})

  def test_validcodes(self):
    for td in self.testdata:
      self.assertEqual(olc.isValid(td['code']), td['isValid'], td)

  def test_fullcodes(self):
    for td in self.testdata:
      self.assertEqual(olc.isFull(td['code']), td['isFull'], td)

  def test_shortcodes(self):
    for td in self.testdata:
      self.assertEqual(olc.isShort(td['code']), td['isShort'], td)


class TestShorten(unittest.TestCase):

  def setUp(self):
    self.testdata = []
    headermap = {
        0: 'fullcode',
        1: 'lat',
        2: 'lng',
        3: 'shortcode',
        4: 'testtype'
    }
    tests_fn = _TEST_DATA + '/shortCodeTests.csv'
    with open(tests_fn, mode='r', encoding='utf-8') as fin:
      for line in fin:
        if line.startswith('#'):
          continue
        td = line.strip().split(',')
        assert len(td) == len(
            headermap), 'Wrong format of testing data: {0}'.format(line)
        td[1] = float(td[1])
        td[2] = float(td[2])
        self.testdata.append({headermap[i]: v for i, v in enumerate(td)})

  def test_full2short(self):
    for td in self.testdata:
      if td['testtype'] == 'B' or td['testtype'] == 'S':
        self.assertEqual(td['shortcode'],
                         olc.shorten(td['fullcode'], td['lat'], td['lng']), td)
      if td['testtype'] == 'B' or td['testtype'] == 'R':
        self.assertEqual(td['fullcode'],
                         olc.recoverNearest(td['shortcode'], td['lat'],
                                            td['lng']), td)


class TestEncoding(unittest.TestCase):

  def setUp(self):
    self.testdata = []
    headermap = {
        0: 'code',
        1: 'lat',
        2: 'lng',
        3: 'latLo',
        4: 'lngLo',
        5: 'latHi',
        6: 'longHi'
    }
    tests_fn = _TEST_DATA + '/encodingTests.csv'
    with open(tests_fn, mode='r', encoding='utf-8') as fin:
      for line in fin:
        if line.startswith('#'):
          continue
        td = line.strip().split(',')
        assert len(td) == len(
            headermap), 'Wrong format of testing data: {0}'.format(line)
        # all values should be numbers except the code
        for i in range(1, len(headermap)):
          td[i] = float(td[i])
        self.testdata.append({headermap[i]: v for i, v in enumerate(td)})

  def test_encoding(self):
    for td in self.testdata:
      codelength = len(td['code']) - 1
      if '0' in td['code']:
        codelength = td['code'].index('0')
      self.assertEqual(td['code'],
                       olc.encode(td['lat'], td['lng'], codelength), td)

  def test_decoding(self):
    precision = 10
    for td in self.testdata:
      decoded = olc.decode(td['code'])
      self.assertEqual(
          round(decoded.latitudeLo, precision),
          round(td['latLo'], precision), td)
      self.assertEqual(
          round(decoded.longitudeLo, precision),
          round(td['lngLo'], precision), td)
      self.assertEqual(
          round(decoded.latitudeHi, precision),
          round(td['latHi'], precision), td)
      self.assertEqual(
          round(decoded.longitudeHi, precision),
          round(td['longHi'], precision), td)

  # Validate that codes generated above 15 significant digits return a 15-digit
  # code
  def test_maxdigits_encoding(self):
    for codelength in [15, 16, 17, 100000]:
      code = olc.encode(37.539669125, -122.375069125, codelength)
      self.assertEqual(code, "849VGJQF+VX7QR4M")

  # Validate that digits after the first 15 are ignored when decoding
  def test_maxdigits_decoding(self):
    maxCharCode = "849VGJQF+VX7QR4M"
    maxChar = olc.decode(maxCharCode)
    maxCharExceeded = olc.decode(maxCharCode + "7QR4M")
    self.assertEqual(maxChar.latitudeCenter, maxCharExceeded.latitudeCenter)
    self.assertEqual(maxChar.longitudeCenter, maxCharExceeded.longitudeCenter)

  # Validate that codes exceeding 15 digits are still valid when all their
  # digits are valid, and invalid when not.
  def test_maxdigits_validity(self):
    maxCharCode = "849VGJQF+VX7QR4M"
    self.assertTrue(olc.isValid(maxCharCode))
    maxCharExceeded = "849VGJQF+VX7QR4M" + "W"
    self.assertTrue(olc.isValid(maxCharExceeded))
    maxCharExceededInvalid = "849VGJQF+VX7QR4M" + "U"
    self.assertFalse(olc.isValid(maxCharExceededInvalid))

if __name__ == '__main__':
  unittest.main()
