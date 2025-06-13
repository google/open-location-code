#  -*- coding: utf-8 -*-

# pylint: disable=redefined-builtin
from io import open
import random
import time
import unittest
from python.openlocationcode import openlocationcode as olc

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
                self.testdata.append({
                    headermap[i]: v for i, v in enumerate(td)
                })

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
                self.testdata.append({
                    headermap[i]: v for i, v in enumerate(td)
                })

    def test_full2short(self):
        for td in self.testdata:
            if td['testtype'] == 'B' or td['testtype'] == 'S':
                self.assertEqual(
                    td['shortcode'],
                    olc.shorten(td['fullcode'], td['lat'], td['lng']), td)
            if td['testtype'] == 'B' or td['testtype'] == 'R':
                self.assertEqual(
                    td['fullcode'],
                    olc.recoverNearest(td['shortcode'], td['lat'], td['lng']),
                    td)


class TestEncoding(unittest.TestCase):

    def setUp(self):
        self.testdata = []
        headermap = {
            0: 'lat',
            1: 'lng',
            2: 'latInt',
            3: 'lngInt',
            4: 'length',
            5: 'code'
        }
        tests_fn = _TEST_DATA + '/encoding.csv'
        with open(tests_fn, mode='r', encoding='utf-8') as fin:
            for line in fin:
                if line.startswith('#'):
                    continue
                td = line.strip().split(',')
                assert len(td) == len(
                    headermap), 'Wrong format of testing data: {0}'.format(line)
                # First two columns are floats, next three are integers.
                td[0] = float(td[0])
                td[1] = float(td[1])
                td[2] = int(td[2])
                td[3] = int(td[3])
                td[4] = int(td[4])
                self.testdata.append({
                    headermap[i]: v for i, v in enumerate(td)
                })

    def test_converting_degrees(self):
        for td in self.testdata:
            got = olc.locationToIntegers(td['lat'], td['lng'])
            # Due to floating point precision limitations, we may get values 1 less than expected.
            self.assertTrue(
                td['latInt'] - 1 <= got[0] <= td['latInt'],
                f'Latitude conversion {td["lat"]}: want {td["latInt"]} got {got[0]}'
            )
            self.assertTrue(
                td['lngInt'] - 1 <= got[1] <= td['lngInt'],
                f'Longitude conversion {td["lng"]}: want {td["lngInt"]} got {got[1]}'
            )

    def test_encoding_degrees(self):
        # Allow a small proportion of errors due to floating point.
        allowedErrorRate = 0.05
        errors = 0
        for td in self.testdata:
            got = olc.encode(td['lat'], td['lng'], td['length'])
            if got != td['code']:
                print(
                    f'olc.encode({td["lat"]}, {td["lng"]}, {td["length"]}) want {td["code"]}, got {got}'
                )
                errors += 1
        self.assertLessEqual(errors / len(self.testdata), allowedErrorRate,
                             "olc.encode error rate too high")

    def test_encoding_integers(self):
        for td in self.testdata:
            self.assertEqual(
                td['code'],
                olc.encodeIntegers(td['latInt'], td['lngInt'], td['length']))


class TestDecoding(unittest.TestCase):

    def setUp(self):
        self.testdata = []
        headermap = {
            0: 'code',
            1: 'length',
            2: 'latLo',
            3: 'lngLo',
            4: 'latHi',
            5: 'longHi'
        }
        tests_fn = _TEST_DATA + '/decoding.csv'
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
                self.testdata.append({
                    headermap[i]: v for i, v in enumerate(td)
                })

    def test_decoding(self):
        precision = 10
        for td in self.testdata:
            decoded = olc.decode(td['code'])
            self.assertAlmostEqual(decoded.latitudeLo, td['latLo'], precision,
                                   td)
            self.assertAlmostEqual(decoded.longitudeLo, td['lngLo'], precision,
                                   td)
            self.assertAlmostEqual(decoded.latitudeHi, td['latHi'], precision,
                                   td)
            self.assertAlmostEqual(decoded.longitudeHi, td['longHi'], precision,
                                   td)


class Benchmark(unittest.TestCase):

    def setUp(self):
        self.testdata = []
        for i in range(0, 100000):
            dec = random.randint(0, 15)
            lat = round(random.uniform(1, 180) - 90, dec)
            lng = round(random.uniform(1, 360) - 180, dec)
            length = random.randint(2, 15)
            if length % 2 == 1:
                length = length + 1
            self.testdata.append(
                [lat, lng, length,
                 olc.encode(lat, lng, length)])

    def test_benchmark(self):
        start_micros = round(time.time() * 1e6)
        for td in self.testdata:
            olc.encode(td[0], td[1], td[2])
        duration_micros = round(time.time() * 1e6) - start_micros
        print('Encoding benchmark: %d passes, %d usec total, %.03f usec each' %
              (len(self.testdata), duration_micros,
               duration_micros / len(self.testdata)))

        start_micros = round(time.time() * 1e6)
        for td in self.testdata:
            olc.decode(td[3])
        duration_micros = round(time.time() * 1e6) - start_micros
        print('Decoding benchmark: %d passes, %d usec total, %.03f usec each' %
              (len(self.testdata), duration_micros,
               duration_micros / len(self.testdata)))


if __name__ == '__main__':
    unittest.main()
