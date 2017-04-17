from open_location_code import OpenLocationCode

OPENLOCATIONCODE = OpenLocationCode()



TEST_DATA = []

def read_test_data(file_object):

    """retrieve data from csv file""" 
    for i, line in enumerate(file_object):
        if line[0] != '#':
            TEST_DATA.append(line.split(",")[0])
    return TEST_DATA


def test_isvalid(file_object):

    """Test whether is a valid full code""" 
    for i in range(len(read_test_data(file_object))):
        status = OPENLOCATIONCODE.isValid(str(read_test_data(file_object)[i]))
        if status:
            print str(read_test_data(file_object)[i]) +" is valid open location code"
        else:
            print str(read_test_data(file_object)[i]) +" is not valid open location code"


def test_is_short(file_object):

    """Test whether is a valid short code""" 
    for i in range(len(read_test_data(file_object))):
        status = OPENLOCATIONCODE.isShort(str(read_test_data(file_object)[i]))
        if status:
            print str(read_test_data(file_object)[i]) +" is valid short open location code"
        else:
            print str(read_test_data(file_object)[i]) +" is not valid short open location code"

def test_isfull(file_object):
    
    """Test whether is a valid full code""" 
    for i in range(len(read_test_data(file_object))):
        status = OPENLOCATIONCODE.isFull(str(read_test_data(file_object)[i]))
        if status:
            print str(read_test_data(file_object)[i]) +" is valid full open location code"
        else:
            print str(read_test_data(file_object)[i]) +" is not valid full open location code"


try:
    VALIDITY_TEST_CSVDATA = open("validityTests.csv", 'r')
    print "VALIDITY"
    test_isvalid(VALIDITY_TEST_CSVDATA)
    print "\n"
    print "SHORT"
    test_is_short(VALIDITY_TEST_CSVDATA)
    print "\n"
    print "FULL"
    test_isfull(VALIDITY_TEST_CSVDATA)

except IOError:
    print "Error: can\'t find file or read data"

