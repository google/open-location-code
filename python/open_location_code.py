from math import floor
import re
OlcCharacterSet = "23456789CFGHJMPQRVWX"
Separator = '+' 
SeparatorPosition = 8
HeightAndWidthDegrees = [20.0, 1.0, .05, .0025, .000125]
LATITUDE_MAXIMUM = 90
LONGITUDE_MAXIMUM = 180
PAD_CHAR = '0'
GRID_SIZE_DEGREES_ = 0.000125
GRID_ROWS_ = 5
GRID_COLUMNS_ = 4
DefaultLength = 10
MinCodeLength = 6

#Encode,decode,recover function calculations
#are taken from current js implementation.

#Returns whether the provided string is a valid Open Location code.
def isValid(OlcCode):

    #Check digits after Pad character
    if (OlcCode.find(PAD_CHAR) != -1):
        CharAfterSep = OlcCode[OlcCode.index(Separator) + len(Separator):]
        if (len(CharAfterSep) > 0):
            return False

    #Checks if Separator is available
    if (OlcCode.find(Separator) == -1):
        return False
    
    #Compare the index of Separator
    if OlcCode.find(Separator) != OlcCode.rfind(Separator):
        return False
    
    #Checks if the index of Separator is greater than Separator position
    if (OlcCode.find(Separator) > SeparatorPosition):
        return False
    
    #Checks if index of sepator is even number 
    if (OlcCode.find(Separator) % 2 != 0):
        return False
    '''
    #Checks if there is character after Separator
    CharAfterSep = OlcCode[OlcCode.index(Separator) + len(Separator):]
    if (len(CharAfterSep) < 2):
        return False
    '''
    #Checks if there is one character.
    if (len(OlcCode) == 1):
        return False

    #Compare given code with OLC characterset
    OlcCode = OlcCode.replace(Separator,'')
    OlcCode = re.sub(PAD_CHAR,'',OlcCode)
    data = list(OlcCode.upper())
    
    countt = 0
    for x in range(len(data)):
        if data[x] in OlcCharacterSet:
            countt+=1

    if countt != len(OlcCode):
        return False

    return True


#Returns if the code is a valid short Open Location Code.
def isShort(OlcCode):

    OlcCode = OlcCode.upper()
    if (isValid(OlcCode) == False):
        return False
    
    #checks the index Separator and compare it with Separator position
    if (OlcCode.find(Separator) <= 0 and OlcCode.find(Separator) >= SeparatorPosition):
        return False

    
    #checks Whether codelength 
    OlcCode = OlcCode.replace(Separator,'')
    if (len(OlcCode) > 7):
        return False
    
    return True
	
#Returns if the code is a valid full Open Location Code
def isFull(OlcCode):
    
    OlcCode = OlcCode.upper()
    #Validating the Open Location Code
    if (isValid(OlcCode) == False):
        return False

    #Checks if the position of Separator is equal to Separator position
    if(OlcCode.find(Separator) != SeparatorPosition):
        return False
    return True


#Encode a location into a sequence of OLC lat/lng pairs.
def encode1(latitude, longitude, codeLength):
	code = ''
	# Make sure latitude and longitude fall into positive ranges.
	PositiveLatitude = latitude + LATITUDE_MAXIMUM
	PositiveLongitude = longitude + LONGITUDE_MAXIMUM
	# Count digits 
	count = 0
	while (count < codeLength):
		# Provides the value of digits in  self place in decimal degrees.
		placeValue = HeightAndWidthDegrees[int(floor(count / 2))]
		# Do the latitude - gets the digit for  self place and subtracts that for
		# the next digit.
		digitValue = int(floor(PositiveLatitude / placeValue))
		PositiveLatitude = PositiveLatitude - (digitValue * placeValue)
		code = code + OlcCharacterSet[digitValue]
		count = count + 1
		# And do the longitude - gets the digit for  self place and subtracts that
		# for the next digit.
		digitValue = int(floor(PositiveLongitude / placeValue))
		PositiveLongitude = PositiveLongitude - (digitValue * placeValue)
		code = code + OlcCharacterSet[digitValue]
		count = count + 1
		#Adding a Separator
		if (count == SeparatorPosition and count < codeLength):
			code = code + Separator
	
	#Adding pad characters.  
	if (len(code) < SeparatorPosition):
        code = code + (PAD_CHAR * (SeparatorPosition - len(code)))

	#if Length of the code equals Separator position add Separator.
	if (len(code) == SeparatorPosition):
		code = code + Separator
	
	return code

#Encode a location using the grid refinement method into an OLC string.
#The grid refinement method divides the area into a grid of 4x5, and uses a
#single character to refine the area.
def encodeCode(latitude, longitude, codeLength):
	code = ''    
	latPlaceValue = GRID_SIZE_DEGREES_    
	lngPlaceValue = GRID_SIZE_DEGREES_    
	# Make sure latitude and longitude so they fall into positive range.
	PositiveLatitude = (latitude + LATITUDE_MAXIMUM) % latPlaceValue    
	PositiveLongitude = (longitude + LONGITUDE_MAXIMUM) % lngPlaceValue
	for i in range(codeLength):
		# Calculating the gridrows and column.
		gridRow = int(floor(PositiveLatitude / (latPlaceValue / GRID_ROWS_)))    
		gridCol = int(floor(PositiveLongitude / (lngPlaceValue / GRID_COLUMNS_)))    
		latPlaceValue = latPlaceValue / GRID_ROWS_    
		lngPlaceValue = lngPlaceValue / GRID_COLUMNS_    
		PositiveLatitude = PositiveLatitude - (gridRow * latPlaceValue)    
		PositiveLongitude = PositiveLongitude - (gridCol * lngPlaceValue)   
		code = code + OlcCharacterSet[gridRow * GRID_COLUMNS_ + gridCol]    
	return code

#Validation of Latitude and longitude calculations
#Taken from js implementation

#Clippling the latitude to the range of -90 to 90
def clipLatitude(latitude):
	return min(90, max(-90, latitude))

#Calculating the area based on the Code Length
def computeLatitudePrecision(codeLength):
	if (codeLength <= 10) :
		return pow(20,floor(codeLength / -2 + 2))
	return pow(20, -3) / pow(GRID_ROWS_, codeLength - 10) 

#Normalising the longitude to the range of -180 to 180
def normalizeLongitude(longitude):
	while (longitude < -180):
		longitude = longitude + 360 
	while (longitude >= 180):
		longitude = longitude - 360 
	return longitude 

#Encodes latitude and longitude into Open Location Code of the provided length.
def encode(latitude,longitude,*args):

        #Checking if args contains value
	emptyArgs = "()"
	if (str(args) == emptyArgs):
		args = "10"
	codeLength = args 

	codeLength = int(''.join(map(str,codeLength)))
	#Validating the Open Location Code Length 
	if (codeLength < 4 or (codeLength < SeparatorPosition and codeLength % 2 == 1)): 
		print ('Invalid Open Location Code length')
	  
	# Checks whether Lat && Long are Valid
	latitude = clipLatitude(latitude) 
	longitude = normalizeLongitude(longitude) 
	# Decrease Latitude so that it will be decoded
	if (latitude == 90):  
		latitude = latitude - computeLatitudePrecision(codeLength) 
	  
	code = encode1(latitude, longitude, min(codeLength, DefaultLength)) 
	#
	if (codeLength > DefaultLength):  
		code = code + encodeCode(latitude, longitude, codeLength - DefaultLength) 
	 
	return code 
 


#Storing lat and long values
class codeArea:
	def __init__(self,latitudeSW,longitudeSW,latitudeNE,longitudeNE,codeLength):
		 self.latitudeSW = latitudeSW 
		 self.longitudeSW = longitudeSW 
		 self.latitudeNE = latitudeNE 
		 self.longitudeNE = longitudeNE 
		 self.codeLength = codeLength 
		 self.latitudeCenter = min(latitudeSW + (latitudeNE - latitudeSW) / 2, LATITUDE_MAXIMUM) 
		 self.longitudeCenter = min(longitudeSW + (longitudeNE - longitudeSW) / 2, LONGITUDE_MAXIMUM) 


#Decodes Open Location Code 
def decode(code): 

	#Replace Separator
	code = code.replace(Separator, '')  
	code = re.sub(PAD_CHAR,'',code)
	code = code.upper() 
	# Decode the lat/long 
	codeArea = decodeLatLong(code[0: DefaultLength])  
	# If less than 10,there is grid refinement decode that.
	if (len(code) <= DefaultLength):
		return codeArea.latitudeSW,codeArea.longitudeSW,codeArea.latitudeNE,codeArea.longitudeNE,codeArea.codeLength
	  
	gridArea = decodeCode(code[DefaultLength:])
	r = codeArea.latitudeSW + gridArea.latitudeSW
	p = codeArea.longitudeSW + gridArea.longitudeSW
	q = codeArea.latitudeSW + gridArea.latitudeNE
	s = codeArea.longitudeSW + gridArea.longitudeNE
	d = codeArea.codeLength + gridArea.codeLength
	return codeArea(r,p,q,s,d)
	
#Decode an OLC code made up of lat/lng pairs.
#This decodes an OLC code made up of alternating latitude and longitude
#characters, encoded using base 20.
def decodeLatLong(code):   
	# Validating latitude and longitude values into positive values
	latitude = decodeSequenceCode(code, 0)  
	longitude = decodeSequenceCode(code, 1)
	
	#Construct the values
	latLo = latitude[0] - LATITUDE_MAXIMUM
	longiLo = longitude[0] - LONGITUDE_MAXIMUM
	latHi = latitude[1] - LATITUDE_MAXIMUM
	longiHi = longitude[1] - LONGITUDE_MAXIMUM
	codeLength = len(code)

	return codeArea(latLo, longiLo, latHi,longiHi, codeLength)


#Decode either a latitude or longitude sequence.
#This decodes the latitude or longitude sequence of a lat/lng pair encoding.
#Starting at the character at position offset, every second character is
#decoded and the value returned.
def decodeSequenceCode(code, offset):
	i = 0  
	value = 0  
	while (i * 2 + offset < len(code)):  
		value += OlcCharacterSet.find(code[i * 2 + offset])*HeightAndWidthDegrees[i]  
		i += 1
	data = value + HeightAndWidthDegrees[i - 1]
	return value,data  
	  
#Decode the grid refinement portion of an OLC code.
#This decodes an OLC code using the grid refinement method.
def decodeCode(code):
	
	latitudeSW = 0.0  
	longitudeSW = 0.0  
	latPlaceValue = GRID_SIZE_DEGREES_  
	lngPlaceValue = GRID_SIZE_DEGREES_  
	i = 0  
	while (i < len(code)):  

		codeIndex = OlcCharacterSet.find(code[i])  
		row = int(floor(codeIndex / GRID_COLUMNS_))  
		col = codeIndex % GRID_COLUMNS_  

		latPlaceValue = latPlaceValue / GRID_ROWS_  
		lngPlaceValue = lngPlaceValue / GRID_COLUMNS_  

		latitudeSW = latitudeSW + (row * latPlaceValue)  
		longitudeSW = longitudeSW + (col * lngPlaceValue)  
		i += 1  
	return codeArea(latitudeSW, longitudeSW, latitudeSW + latPlaceValue,longitudeSW + lngPlaceValue, len(code)) 


def shortencode(code, latitude, longitude):

	limit = 0
	if (isFull(code) == False):
		limit = limit + 1
		print("13654")

	if (code.find(PAD_CHAR) != -1):
		limit = limit + 1


	if (limit == 0):
		cd = decode(code)
		codeArea1 = codeArea(cd[0],cd[1],cd[2],cd[3],cd[4])

		latitudeDiff = abs(latitude - (codeArea1.latitudeSW + (codeArea1.latitudeNE - codeArea1.latitudeSW) / 2))
		longitudeDiff = abs(longitude - (codeArea1.longitudeSW + (codeArea1.longitudeNE - codeArea1.longitudeSW) / 2))    

		if (latitudeDiff < 0.0125 and longitudeDiff < 0.0125):
			return code[6:]
		
		if (latitudeDiff < 0.25 and longitudeDiff < 0.25):
			return code[4:]
	else:
		return "Invalid Full OLC or OLC is Padded"




def recoverNearest(code, latitude, longitude) :

	# Checks whether latitude and longitude are valid.
	latitude = clipLatitude(latitude) 
	longitude = normalizeLongitude(longitude) 

	# Convert to Uppercase
	code = code.upper() 
	# Calculate the length of pad characters
	padLength = SeparatorPosition - code.find(Separator) 
	# Calculate padded area in degrees.
	padAreaResolution = pow(20, 2 - (padLength / 2)) 
	# Calculate center to an edge in degrees.
	centerToEdgeDis = padAreaResolution / 2.0 

	# rounds a Lat and Long DOWNWARDS to the nearest integer 
	floorLatitude = floor(latitude / padAreaResolution) * padAreaResolution 
	floorLongitude = floor(longitude / padAreaResolution) * padAreaResolution 

	# Decode the lat and long.
	codeAre = decode(encode(floorLatitude, floorLongitude,10)[0:padLength] + code) 
	codeArea1 = codeArea(codeAre[0],codeAre[1],codeAre[2],codeAre[3],codeAre[4])
	# Calculate degrees latitude
	degreesDifference = codeArea1.latitudeCenter - latitude 
	if (degreesDifference > centerToEdgeDis):
		# If the center of the short code is more than half a cell east,
		# then the best match will be one position west.
		codeArea1.latitudeCenter = codeArea1.latitudeCenter - padAreaResolution 
	elif (degreesDifference < -centerToEdgeDis) :
		# If the center of the short code is more than half a cell west,
		# then the best match will be one position east.
		codeArea1.latitudeCenter = codeArea1.latitudeCenter + padAreaResolution 
	 
	# Calculate degrees longitude 
	degreesDifference = codeArea1.longitudeCenter - longitude 
	if (degreesDifference > centerToEdgeDis) :
		codeArea1.longitudeCenter = codeArea1.longitudeCenter - padAreaResolution 
	elif (degreesDifference < -centerToEdgeDis) :
		codeArea1.longitudeCenter = codeArea1.longitudeCenter + padAreaResolution 
	 
	return encode(codeArea1.latitudeCenter, codeArea1.longitudeCenter, codeArea1.codeLength) 
	