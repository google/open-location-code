from open_location_code import OpenLocationCode

OPENLOCATIONCODE = OpenLocationCode()

def read_test_data(fileObject):

    for i, line in enumerate(fileObject):
        if line[0] != '#':

            data = line.split(",")
            lat = float(data[1])
            longi = float(data[2])
            encoded_code = OPENLOCATIONCODE.encode(lat, longi)
            print "Encoded code: "+encoded_code+", with "+str(lat)+ \
                   " Latitude and "+str(longi)+" longitude"
    
try:
    encoding_file = open("encodingTests.csv", 'r')
    read_test_data(encoding_file)

except IOError:
    print "Error: can\'t find file or read data"


