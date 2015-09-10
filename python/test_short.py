from open_location_code import OpenLocationCode

OPENLOCATIONCODE = OpenLocationCode()


def test_shorten(fileObject):

    for i, line in enumerate(fileObject):
        if line[0] != '#':

            data = line.split(",")
            code = data[0]
            lat = float(data[1])
            longi = float(data[2])
            short_code = OPENLOCATIONCODE.shortencode(code, lat, longi)
            recover = OPENLOCATIONCODE.recoverNearest(code, lat, longi)
            assert(short_code != code), "Failed to shorten the open location code" + code
            assert(recover != code), "Failed to recover the open location code" + code
            print "shorten code: "+short_code+", RecoverNearest: "+recover


try:
    short_code_file = open("shortCodeTests.csv", 'r')
    test_shorten(short_code_file)

except IOError:
    print "Error: can\'t find file or read data"



