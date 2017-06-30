import pluscodes
import unittest

class TestValalidity(unittest.TestCase):
    def test_validfullcodes(self):
        self.assertTrue(pluscodes.isValid('8FWC2345+G6') and pluscodes.isFull('8FWC2345+G6'))
        self.assertTrue(pluscodes.isValid('8FWC2345+G6G') and pluscodes.isFull('8FWC2345+G6G'))
        self.assertTrue(pluscodes.isValid('8fwc2345+') and pluscodes.isFull('8fwc2345+'))
        self.assertTrue(pluscodes.isValid('8FWCX400+') and pluscodes.isFull('8FWCX400+'))
        self.assertFalse(pluscodes.isShort('8FWCX400+'))
        self.assertFalse(pluscodes.isShort('8fwc2345+'))

    def test_validshortcodes(self):
        self.assertTrue(pluscodes.isValid('WC2345+G6g') and pluscodes.isShort('WC2345+G6g'))
        self.assertTrue(pluscodes.isValid('2345+G6') and pluscodes.isShort('2345+G6'))
        self.assertTrue(pluscodes.isValid('45+G6') and pluscodes.isShort('45+G6'))
        self.assertTrue(pluscodes.isValid('+G6') and pluscodes.isShort('+G6'))
        self.assertFalse(pluscodes.isFull('45+G6'))
        self.assertFalse(pluscodes.isFull('WC2345+G6g'))

    def test_invalidcodes(self):
        self.assertFalse(pluscodes.isValid('G+'))
        self.assertFalse(pluscodes.isValid('+'))
        self.assertFalse(pluscodes.isValid('8FWC2345+G'))
        self.assertFalse(pluscodes.isValid('8FWC2_45+G6'))
        self.assertFalse(pluscodes.isValid('8FWC2η45+G6'))
        self.assertFalse(pluscodes.isValid('8FWC2345+G6+'))
        self.assertFalse(pluscodes.isValid('8FWC2300+G6'))
        self.assertFalse(pluscodes.isValid('WC2300+G6g'))
        self.assertFalse(pluscodes.isValid('WC2345+G'))

class TestShorten(unittest.TestCase):
    def test_full2short(self):
        self.assertEqual('+2VX', pluscodes.shorten('9C3W9QCJ+2VX',51.3701125,-1.217765625))
        self.assertEqual('CJ+2VX', pluscodes.shorten('9C3W9QCJ+2VX',51.3708675,-1.217765625))
        self.assertEqual('CJ+2VX', pluscodes.shorten('9C3W9QCJ+2VX',51.3701125,-1.217010625))
        self.assertEqual('9QCJ+2VX', pluscodes.shorten('9C3W9QCJ+2VX',51.3852125,-1.217765625))

class TestEncode(unittest.TestCase):
    def test_encode(self):
        self.assertEqual('7FG49Q00+', pluscodes.encode(20.375,2.775,6))
        self.assertEqual('7FG49QCJ+2V', pluscodes.encode(20.3700625,2.7821875))
        self.assertEqual('7FG49QCJ+2VX', pluscodes.encode(20.3701125,2.782234375,11))
        self.assertEqual('7FG49QCJ+2VXGJ', pluscodes.encode(20.3701135,2.78223535156,13))
        self.assertEqual('8FVC2222+22', pluscodes.encode(47.0,8.0))
        self.assertEqual('4VCPPQGP+Q9', pluscodes.encode(-41.2730625,174.7859375))
        self.assertEqual('62G20000+', pluscodes.encode(0.5,-179.5,4))
        self.assertEqual('22220000+', pluscodes.encode(-90,-180,4))
        self.assertEqual('CFX30000+', pluscodes.encode(90,1,4))
        self.assertEqual('62H20000+', pluscodes.encode(1,180,4))

if __name__ == '__main__':
    unittest.main()
