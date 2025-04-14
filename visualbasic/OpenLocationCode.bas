Attribute VB_Name = "OpenLocationCode"

' Copyright 2017 Google Inc. All rights reserved.
'
' Licensed under the Apache License, Version 2.0 (the 'License');
' you may not use this file except in compliance with the License.
' You may obtain a copy of the License at
'
' http://www.apache.org/licenses/LICENSE-2.0
'
' Unless required by applicable law or agreed to in writing, software
' distributed under the License is distributed on an 'AS IS' BASIS,
' WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
' See the License for the specific language governing permissions and
' limitations under the License.
'
' Convert locations to and from short codes.
'
' Plus Codes are short, 10-11 character codes that can be used instead
' of street addresses. The codes can be generated and decoded offline, and use
' a reduced character set that minimises the chance of codes including words.
'
' This file provides a VBA implementation (that may also run in OpenOffice or
' LibreOffice). A full reference of Open Location Code is provided at
' https://github.com/google/open-location-code.
'
' This library provides the following functions:
' OLCIsValid - passed a string, returns boolean True if the string is a valid
'     Open Location Code.
' OLCIsShort - passed a string, returns boolean True if the string is a valid
'     shortened Open Location Code (i.e. has from 2 to 8 characters removed
'     from the start).
' OLCIsFull - passed a string, returns boolean True if the string is a valid
'     full length Open Location Code.
' OLCEncode - encodes a latitude and longitude into an Open Location Code.
'     Defaults to standard precision, or the code length can optionally be
'     specified.
' OLCDecode - Decodes a passed string and returns an OLCArea data structure.
' OLCDecode2Array - Same as OLCDecode but returns the coordinates in an
'     array, easier to use within Excel.
' OLCShorten - Passed a code and a location, works out if leading digits in
'     the code can be omitted.
' OLCRecoverNearest - Passed a short code and a location, returns the nearest
'     matching full length code.
'
' A testing subroutine is provided using the test cases from the Github
' project. Re-run this if you make any code changes.
'
' Enable this flag when running in OpenOffice/Libre Office.
'Option VBASupport 1

' Warn on various errors.
Option Explicit

' Provides the length of a normal precision code, approximately 14x14 meters.
Public Const CODE_PRECISION_NORMAL As Integer = 10

' Provides the length of an extra precision code, approximately 2x3 meters.
Public Const CODE_PRECISION_EXTRA As Integer = 11

' The structure returned when decoding.
Public Type OLCArea
  LatLo As Double
  LngLo As Double
  LatHi As Double
  LngHi As Double
  LatCenter As Double
  LngCenter As Double
  CodeLength As Integer
End Type

' A separator used to break the code into two parts to aid memorability.
Private Const SEPARATOR_ As String = "+"

' The number of characters to place before the separator.
Private Const SEPARATOR_POSITION_ As Integer = 8

' The character used to pad codes.
Private Const PADDING_CHARACTER_ As String = "0"

' The character set used to encode the values.
Private Const CODE_ALPHABET_ As String = "23456789CFGHJMPQRVWX"

' The base to use to convert numbers to/from.
Private Const ENCODING_BASE_ As Integer = 20

' The maximum value for latitude in degrees.
Private Const LATITUDE_MAX_ As Double = 90

' The maximum value for longitude in degrees.
Private Const LONGITUDE_MAX_ As Double = 180

' Minimum number of digits in a code.
Private Const MIN_DIGIT_COUNT_ As Integer = 2

' Maximum number of digits in a code.
Private Const MAX_DIGIT_COUNT_ As Integer = 15

' Maximum code length using lat/lng pair encoding. The area of such a
' code is approximately 13x13 meters (at the equator), and should be suitable
' for identifying buildings. This excludes prefix and separator characters.
Private Const PAIR_CODE_LENGTH_ As Integer = 10

' Number of columns in the grid refinement method.
Private Const GRID_COLUMNS_ As Integer = 4

' Number of rows in the grid refinement method.
Private Const GRID_ROWS_ As Integer = 5

' Number of grid digits.
Private Const GRID_CODE_LENGTH_ As Integer = MAX_DIGIT_COUNT_ - PAIR_CODE_LENGTH_

' Size of the initial grid in degrees.
Private Const GRID_SIZE_DEGREES_ As Double = 1 / 8000

' Degree resolution for latitude.
Private Const FINAL_LAT_PRECISION_ As Long = 8000 * (GRID_ROWS_ ^ GRID_CODE_LENGTH_)

' Degree resolution for longitude.
Private Const FINAL_LNG_PRECISION_ As Long = 8000 * (GRID_COLUMNS_ ^ GRID_CODE_LENGTH_)

' Minimum length of a code that can be shortened.
Private Const MIN_TRIMMABLE_CODE_LEN_ As Integer = 6

' Determines if a code is valid.
'
' To be valid, all characters must be from the Open Location Code character
' set with at most one separator. The separator can be in any even-numbered
' position up to the eighth digit. If the code is padded, there must be an
' even number of digits before the padded section, an even number of padding
' characters, followed only by a single separator.
Public Function OLCIsValid(ByVal code As String) As Boolean
  Dim separatorPos, paddingStart As Integer
  separatorPos = InStr(code, SEPARATOR_)
  paddingStart = InStr(code, PADDING_CHARACTER_)
  OLCIsValid = True
  If code = "" Then
    OLCIsValid = False
  ElseIf separatorPos = 0 Then
    ' A separator is required.
    OLCIsValid = False
  ElseIf InStr(separatorPos + 1, code, SEPARATOR_) <> 0 Then
    ' Must be only one separator.
    OLCIsValid = False
  ElseIf Len(code) = 1 Then
    ' Is the separator the only character?
    OLCIsValid = False
  ElseIf separatorPos > SEPARATOR_POSITION_ + 1 Or separatorPos - 1 Mod 2 = 1 Then
    ' The separator is in an illegal position.
    OLCIsValid = False
  ElseIf paddingStart > 0 Then
    If separatorPos < SEPARATOR_POSITION_ Then
      ' Short codes cannot have padding
      OLCIsValid = False
    ElseIf paddingStart < 2 Then
      ' Cannot start with padding characters.
      OLCIsValid = False
    ElseIf paddingStart - 1 Mod 2 = 1 Then
      ' Padding characters must be after an even number of digits.
      OLCIsValid = False
    ElseIf Len(code) > separatorPos Then
      ' Padded codes must not have anything after the separator.
      OLCIsValid = False
    Else
      ' Get from the first padding character to the separator.
      Dim paddingSection As String
      paddingSection = Mid(code, paddingStart, separatorPos - paddingStart)
      paddingSection = Replace(paddingSection, PADDING_CHARACTER_, "")
      ' After removing padding characters, we mustn't have anything left.
      If paddingSection <> "" Then
        OLCIsValid = False
      End If
    End If
  ElseIf Len(code) - separatorPos = 1 Then
    ' Must be more than one character after the separator.
    OLCIsValid = False
  End If
  If OLCIsValid = True Then
    ' If the structural checks pass, check all characters are valid.
    Dim i As Integer
    Dim c As String
    For i = 1 To Len(code)
      c = Ucase(Mid(code, i, 1))
      If c <> PADDING_CHARACTER_ And c <> SEPARATOR_ And InStr(CODE_ALPHABET_, c) = 0 Then
        OLCIsValid = False
        Exit For
      End If
    Next
  End If
End Function

' Determines if a code is a valid short code.
Public Function OLCIsShort(ByVal code As String)
  OLCIsShort = False
  If OLCIsValid(code) And InStr(code, SEPARATOR_) > 0 And InStr(code, SEPARATOR_) < SEPARATOR_POSITION_ Then
    ' If there are less characters than expected before the SEPARATOR.
    OLCIsShort = True
  End If
End Function

' Determines if a code is a valid full Open Location Code.
Public Function OLCIsFull(ByVal code As String) As Boolean
  OLCIsFull = True
  If Not OLCIsValid(code) Then
    OLCIsFull = False
  ElseIf OLCIsShort(code) Then
    OLCIsFull = False
  Else
    Dim ucode As String
    Dim val As Integer
    ucode = Ucase(code)
    ' Work out what the first two characters indicate for latitude and longitude.
    val = (InStr(CODE_ALPHABET_, Mid(ucode, 1, 1)) - 1) * ENCODING_BASE_
    If val >= LATITUDE_MAX_ * 2 Then
      OLCIsFull = False
    ElseIf Len(code) > 1 Then
      val = (InStr(CODE_ALPHABET_, Mid(ucode, 2, 1)) - 1) * ENCODING_BASE_
      If val >= LONGITUDE_MAX_ * 2 Then
        OLCIsFull = False
      End If
    End If
  End If
End Function

' Encode a location into an arbitrary precision Open Location Code.
Public Function OLCEncode(ByVal latitude As Double, ByVal longitude As Double, Optional codeLength As Integer = 10) As String
  If codeLength = 0 Then
    codeLength = CODE_PRECISION_NORMAL
  End If
  If codeLength < MIN_DIGIT_COUNT_ Then
    Err.raise vbObjectError + 513, "OLCEncodeWithLength", "Invalid code length"
  End If
  If codeLength > MAX_DIGIT_COUNT_ Then
    Err.raise vbObjectError + 513, "OLCEncodeWithLength", "Invalid code length"
  End If
  If codeLength < PAIR_CODE_LENGTH_ And codeLength \ 2 = 1 Then
    Err.raise vbObjectError + 513, "OLCEncodeWithLength", "Invalid code length"
  End If
  ' We use Doubles for the latitude and longitude, even though we will use them as integers.
  ' The reason is that we want to use this code in Excel and LibreOffice, but the LibreOffice
  ' Long type is only 32 bits, –2147483648 and 2147483647, which is too small.
  Dim lat As Double, lng As Double
  ' i is used in loops.
  Dim i As Integer

  ' Convert latitude into a positive integer clipped into the range 0-(just
  ' under 180*2.5e7). Latitude 90 needs to be adjusted to be just less, so the
  ' returned code can also be decoded.
  lat = Round(latitude * FINAL_LAT_PRECISION_)
  lat = lat + LATITUDE_MAX_ * FINAL_LAT_PRECISION_
  If lat < 0 Then
    lat = 0
  ElseIf lat >= 2 * LATITUDE_MAX_ * FINAL_LAT_PRECISION_ Then
    lat = 2 * LATITUDE_MAX_ * FINAL_LAT_PRECISION_ - 1
  End If
  ' Convert longitude into a positive integer and normalise it into the range 0-360*8.192e6.
  lng = Round(longitude * FINAL_LNG_PRECISION_)
  lng = lng + LONGITUDE_MAX_ * FINAL_LNG_PRECISION_
  If lng < 0 Then
    lng = doubleMod(lng, (2 * LONGITUDE_MAX_ * FINAL_LNG_PRECISION_)) + 2 * LONGITUDE_MAX_ * FINAL_LNG_PRECISION_
  ElseIf lng >= 2 * LONGITUDE_MAX_ * FINAL_LNG_PRECISION_ Then
    lng = doubleMod(lng, (2 * LONGITUDE_MAX_ * FINAL_LNG_PRECISION_))
  EndIf

  ' Build up the code in an array.
  Dim code(MAX_DIGIT_COUNT_) As String
  code(SEPARATOR_POSITION_) = SEPARATOR_

  ' Compute the grid part of the code if necessary.
  Dim latDigit As Integer
  Dim lngDigit As Integer
  If codeLength > PAIR_CODE_LENGTH_ Then
      For i = MAX_DIGIT_COUNT_ - PAIR_CODE_LENGTH_ To 1 Step -1
        latDigit = CInt(doubleMod(lat, GRID_ROWS_))
        lngDigit = CInt(doubleMod(lng, GRID_COLUMNS_))
        code(SEPARATOR_POSITION_ + 2 + i) = Mid(CODE_ALPHABET_, 1 + latDigit * GRID_COLUMNS_ + lngDigit, 1)
        lat = Int(lat / GRID_ROWS_)
        lng = Int(lng / GRID_COLUMNS_)
      Next
  Else
    lat = Int(lat / (GRID_ROWS_ ^ GRID_CODE_LENGTH_))
    lng = Int(lng / (GRID_COLUMNS_ ^ GRID_CODE_LENGTH_))
  End If

  ' Add the pair after the separator.
  code(SEPARATOR_POSITION_ + 1) = Mid(CODE_ALPHABET_, 1 + doubleMod(lat, ENCODING_BASE_), 1)
  code(SEPARATOR_POSITION_ + 2) = Mid(CODE_ALPHABET_, 1 + doubleMod(lng, ENCODING_BASE_), 1)
  lat = Int(lat / ENCODING_BASE_)
  lng = Int(lng / ENCODING_BASE_)

  ' Compute the pair section of the code.
  For i = Int(PAIR_CODE_LENGTH_ / 2) + 1 To 0 Step -2
    code(i) = Mid(CODE_ALPHABET_, 1 + doubleMod(lat, ENCODING_BASE_), 1)
    code(i + 1) = Mid(CODE_ALPHABET_, 1 + doubleMod(lng, ENCODING_BASE_), 1)
    lat = Int(lat / ENCODING_BASE_)
    lng = Int(lng / ENCODING_BASE_)
  Next
  Dim finalCodeLen As Integer
  finalCodeLen = codeLength
  ' Add padding characters if necessary.
  If codeLength < SEPARATOR_POSITION_ Then
  	For i = codeLength To SEPARATOR_POSITION_ - 1
  	  code(i) = PADDING_CHARACTER_
  	Next
  	finalCodeLen = SEPARATOR_POSITION_
  EndIf
  ' Build the final code and return it.
  Dim finalCode As String
  For i = 0 To finalCodeLen
    finalCode = finalCode & code(i)
  Next
  OLCEncode = finalCode
End Function

' Decodes an Open Location Code into an array of latlo, lnglo, latcenter, lngcenter, lathi, lnghi, codelength.
Public Function OLCDecode2Array(ByVal code As String) As Variant
  Dim codeArea As OLCArea
  codeArea = OLCDecode(code)
  Dim result(6) As Double
  result(0) = codeArea.LatLo
  result(1) = codeArea.LngLo
  result(2) = codeArea.LatCenter
  result(3) = codeArea.LngCenter
  result(4) = codeArea.LatHi
  result(5) = codeArea.LngHi
  result(6) = codeArea.CodeLength
  OLCDecode2Array = result
End Function

' Decodes an Open Location Code into its location coordinates.
' Returns a CodeArea object.
Public Function OLCDecode(ByVal code As String) As OLCArea
  If Not OLCIsFull(code) Then
    Err.raise vbObjectError + 513, "OLCDecode", "Invalid code"
  End If
  Dim c As String
  Dim codeArea As OLCArea
  ' Strip out separator character (we've already established the code is
  ' valid so the maximum is one), padding characters and convert to upper
  ' case.
  c = Replace(code, SEPARATOR_, "")
  c = Replace(c, PADDING_CHARACTER_, "")
  c = Ucase(c)
  ' Decode the lat/lng pairs.
  codeArea = decodePairs(Mid(c, 1, PAIR_CODE_LENGTH_))
  ' If there is a grid refinement component, decode that.
  If Len(c) > PAIR_CODE_LENGTH_ Then
    Dim gridArea As OLCArea
    gridArea = decodeGrid(Mid(c, PAIR_CODE_LENGTH_ + 1))
    codeArea.LatHi = codeArea.LatLo + gridArea.LatHi
    codeArea.LngHi = codeArea.LngLo + gridArea.LngHi
    codeArea.LatLo = codeArea.LatLo + gridArea.LatLo
    codeArea.LngLo = codeArea.LngLo + gridArea.LngLo
  End If
  codeArea.LatCenter = (codeArea.LatLo + codeArea.LatHi) / 2
  codeArea.LngCenter = (codeArea.LngLo + codeArea.LngHi) / 2
  codeArea.CodeLength = Len(c)
  OLCDecode = codeArea
End Function

' Remove characters from the start of an OLC code based on a reference location.
Public Function OLCShorten(ByVal code As String, ByVal latitude As Double, ByVal longitude As Double) As String
  If Not OLCIsFull(code) Then
    Err.raise vbObjectError + 513, "OLCDecode", "Invalid code"
  End If
  If InStr(code, PADDING_CHARACTER_) <> 0 Then
    Err.raise vbObjectError + 513, "OLCDecode", "Invalid code"
  End If
  Dim codeArea As OLCArea
  codeArea = OLCDecode(code)
  If codeArea.CodeLength < MIN_TRIMMABLE_CODE_LEN_ Then
    Err.raise vbObjectError + 513, "OLCDecode", "Invalid code"
  End If
  Dim lat, lng, range, precision As Double
  Dim i, trim As Integer
  ' Ensure that the latitude and longitude are valid.
  lat = clipLatitude(latitude)
  lng = normalizeLongitude(longitude)
  ' How close are the latitude and longitude to the code center?
  range = doubleMax(doubleABS(codeArea.LatCenter - lat), doubleABS(codeArea.LngCenter - lng))
  precision = CDbl(ENCODING_BASE_)
  For i = 0 To 3
    If range < precision * 0.3 Then
      trim = (i + 1) * 2
    End If
    precision = precision / ENCODING_BASE_
  Next
  OLCShorten = Mid(Ucase(code), trim + 1)
End Function

' Recover the nearest matching code to a specified location.
Public Function OLCRecoverNearest(ByVal code As String, ByVal latitude As Double, ByVal longitude As Double) As String
  If OLCIsFull(code) Then
    OLCRecoverNearest = Ucase(code)
  ElseIf Not OLCIsShort(code) Then
    Err.raise vbObjectError + 513, "OLCDecode", "Invalid code"
  Else
    Dim lat, lng, resolution, halfRes As Double
    Dim paddingLength As Integer
    Dim codeArea As OLCArea
    ' Ensure that the latitude and longitude are valid.
    lat = clipLatitude(latitude)
    lng = normalizeLongitude(longitude)
    ' Compute the number of digits we need to recover.
    paddingLength = SEPARATOR_POSITION_ - InStr(code, SEPARATOR_) + 1
    ' The resolution (height and width) of the padded area in degrees.
    resolution = ENCODING_BASE_ ^ (2 - (paddingLength / 2))
    ' Distance from the center to an edge (in degrees).
    halfRes = resolution / 2
    ' Use the reference location to pad the supplied short code and decode it.
    codeArea = OLCDecode(Mid(OLCEncode(lat, lng), 1, paddingLength) + code)
    ' How many degrees latitude is the code from the reference? If it is more
    ' than half the resolution, we need to move it nort or south but keep it
    ' within -90 to 90 degrees.
    If lat + halfRes < codeArea.LatCenter And codeArea.LatCenter - resolution > LATITUDE_MAX_ Then
      ' If the proposed code is more than half a cell north of the reference location,
      ' it's too far, and the best match will be one cell south.
      codeArea.LatCenter = codeArea.LatCenter - resolution
    ElseIf lat - halfRes > codeArea.LatCenter And codeArea.LatCenter + resolution < LATITUDE_MAX_ Then
      ' If the proposed code is more than half a cell south of the reference location,
      ' it's too far, and the best match will be one cell north.
      codeArea.LatCenter = codeArea.LatCenter + resolution
    End If
    ' How many degrees longitude is the code from the reference?
    If lng + halfRes < codeArea.LngCenter Then
      codeArea.LngCenter = codeArea.LngCenter - resolution
    ElseIf lng - halfRes > codeArea.LngCenter Then
      codeArea.LngCenter = codeArea.LngCenter + resolution
    End If
    OLCRecoverNearest = OLCEncode(codeArea.LatCenter, codeArea.LngCenter, codeArea.CodeLength)
  End If
End Function

' Clip a latitude into the range -90 to 90.
Private Function clipLatitude(ByVal latitude As Double) As Double
  If latitude >= -90 Then
    If latitude <= 90 Then
      clipLatitude = latitude
    Else
      clipLatitude = 90
    End If
  Else
    clipLatitude = -90
  End If
End Function

' Normalize a longitude into the range -180 to 180, not including 180.
Private Function normalizeLongitude(ByVal longitude As Double) As Double
  Dim lng As Double
  lng = longitude
  Do While lng < -180
    lng = lng + 360
  Loop
  Do While lng >= 180
    lng = lng - 360
  Loop
  normalizeLongitude = lng
End Function

' Compute the latitude precision value for a given code length.
' Lengths <= 10 have the same precision for latitude and longitude, but
' lengths > 10 have different precisions due to the grid method having
' fewer columns than rows.
Private Function computeLatitudePrecision(codeLength) As Double
  If codeLength <= 10 Then
    computeLatitudePrecision = ENCODING_BASE_ ^ Int(codeLength / -2 + 2)
  Else
    computeLatitudePrecision = (ENCODING_BASE_ ^ -3) / (GRID_ROWS_ ^ (codeLength - 10))
  End If
End Function

' Merge code parts into a single code.
Private Function mergeCode(ByVal latCode As String, ByVal lngCode As String, ByVal gridCode As String) As String
  Dim code As String
  Dim i, digitCount As Integer
  code = ""
  digitCount = 0
  For i = 1 To Len(latCode)
    code = code + Mid(latCode, i, 1)
    code = code + Mid(lngCode, i, 1)
    digitCount = digitCount + 2
    If digitCount = SEPARATOR_POSITION_ Then
      code = code + SEPARATOR_
    End If
  Next
  Do While Len(code) < SEPARATOR_POSITION_
    code = code + PADDING_CHARACTER_
  Loop
  If Len(code) = SEPARATOR_POSITION_ Then
    code = code + SEPARATOR_
  End If
  code = code + gridCode
  mergeCode = code
End Function

' Decode an OLC code made up of lat/lng pairs.
Private Function decodePairs(code) As OLCArea
  Dim lat, lng, precision As Double
  Dim offset As Integer
  lat = 0
  lng = 0
  precision = CDbl(ENCODING_BASE_)
  offset = 1
  Do While offset < Len(code)
    Dim c As String
    ' Get the lat digit.
    c = Mid(code, offset, 1)
    offset = offset + 1
    lat = lat + (InStr(CODE_ALPHABET_, c) - 1) * precision
    ' Get the lng digit.
    c = Mid(code, offset, 1)
    offset = offset + 1
    lng = lng + (InStr(CODE_ALPHABET_, c) - 1) * precision
    If offset < Len(code) Then
      precision = precision / ENCODING_BASE_
    End If
  Loop
  ' Correct the values and set them into the CodeArea object.
  Dim codeArea As OLCArea
  codeArea.LatLo = lat - LATITUDE_MAX_
  codeArea.LngLo = lng - LONGITUDE_MAX_
  codeArea.LatHi = codeArea.LatLo + precision
  codeArea.LngHi = codeArea.LngLo + precision
  codeArea.CodeLength = Len(code)
  decodePairs = codeArea
End Function

' Decode the grid refinement portion of an OLC code.
Private Function decodeGrid(ByVal code As String) As OLCArea
  Dim gridOffSet As OLCArea
  Dim latVal, lngVal As Double
  Dim i, d, row, col As Integer
  latVal = CDbl(GRID_SIZE_DEGREES_)
  lngVal = CDbl(GRID_SIZE_DEGREES_)
  For i = 1 To Len(code)
    d = InStr(CODE_ALPHABET_, Mid(code, i, 1)) - 1
    row = Int(d / GRID_COLUMNS_)
    col = d Mod GRID_COLUMNS_
    latVal = latVal / GRID_ROWS_
    lngVal = lngVal / GRID_COLUMNS_
    gridOffSet.LatLo = gridOffSet.LatLo + row * latVal
    gridOffSet.LngLo = gridOffSet.LngLo + col * lngVal
  Next
  gridOffSet.LatHi = gridOffSet.LatLo + latVal
  gridOffSet.LngHi = gridOffSet.LngLo + lngVal
  decodeGrid = gridOffSet
End Function

' Provide a mod function.
' (In OpenOffice Basic the Mod operator only works with Integers.)
Private Function doubleMod(ByVal number As Double, ByVal divisor As Double) As Double
  doubleMod = number - divisor * Int(number / divisor)
End Function

' Provide a max function.
Private Function doubleMax(ByVal number1 As Double, ByVal number2 As Double) As Double
  If number1 > number2 Then
    doubleMax = number1
  Else
    doubleMax = number2
  End If
End Function

' Provide an ABS function for doubles.
Private Function doubleABS(ByVal number As Double) As Double
  If number < 0 Then
    doubleABS = number * -1
  Else
    doubleABS = number
  End If
End Function

' Test two doubles and returns true if they are close enough.
' Used by the test routine since we quickly hit floating point errors.
Private Function doubleEquals(ByVal number1 As Double, ByVal number2 As Double) As Boolean
  If doubleABS(number1 - number2) < 0.0000000001 Then
    doubleEquals = True
  Else
    doubleEquals = False
  End If
End Function

' This is a subroutine to test the functions of the library, using test data
' from the Github project. If you make any changes to the above code, run this
' subroutine to check that your changes have not introduced errors. If you
' identify tests that are faulty or would like to add tests, go to the
' Github project and raise an issue.
Sub TestOLCLibrary()
  Dim i As Integer
  Dim c As String
  Dim a As OLCArea

  Dim validity(17) As Variant
  ' Fields code,isValid,isShort,isFull
  validity(0) = Array("8fwc2345+G6", "true", "false", "true")
  validity(1) = Array("8FWC2345+G6G", "true", "false", "true")
  validity(2) = Array("8fwc2345+", "true", "false", "true")
  validity(3) = Array("8FWCX400+", "true", "false", "true")
  validity(4) = Array("WC2345+G6g", "true", "true", "false")
  validity(5) = Array("2345+G6", "true", "true", "false")
  validity(6) = Array("45+G6", "true", "true", "false")
  validity(7) = Array("+G6", "true", "true", "false")
  validity(8) = Array("G+", "false", "false", "false")
  validity(9) = Array("+", "false", "false", "false")
  validity(10) = Array("8FWC2345+G", "false", "false", "false")
  validity(11) = Array("8FWC2_45+G6", "false", "false", "false")
  validity(12) = Array("8FWC2η45+G6", "false", "false", "false")
  validity(13) = Array("8FWC2345+G6+", "false", "false", "false")
  validity(14) = Array("8FWC2300+G6", "false", "false", "false")
  validity(15) = Array("WC2300+G6g", "false", "false", "false")
  validity(16) = Array("WC2345+G", "false", "false", "false")
  For i = 0 To 16
    Dim v, s, f As Boolean
    v = OLCIsValid(validity(i)(0))
    s = OLCIsShort(validity(i)(0))
    f = OLCIsFull(validity(i)(0))
    If v <> (validity(i)(1) = "true") Then
      MsgBox ("IsValid test " + CStr(i) + ", expected: " + CStr(validity(i)(1) = "true") + ", actual: " + CStr(v))
      Exit Sub
    End If
    If s <> (validity(i)(2) = "true") Then
      MsgBox ("IsShort test " + CStr(i) + ", expected: " + CStr(validity(i)(2) = "true") + ", actual: " + CStr(s))
      Exit Sub
    End If
    If f <> (validity(i)(3) = "true") Then
      MsgBox ("IsFull test " + CStr(i) + ", expected: " + CStr(validity(i)(3) = "true") + ", actual: " + CStr(f))
      Exit Sub
    End If
  Next

  Dim encodingCodes(14) As String
  ' Fields are lat,lng,latLo,lngLo,latHi,lngHi
  Dim encodingCoordinates(14) As Variant
  encodingCodes(0) = "7fG49Q00+"
  encodingCoordinates(0) = Array(20.375, 2.775, 20.35, 2.75, 20.4, 2.8)
  encodingCodes(1) = "7FG49QCJ+2v"
  encodingCoordinates(1) = Array(20.3700625, 2.7821875, 20.37, 2.782125, 20.370125, 2.78225)
  encodingCodes(2) = "7FG49QCJ+2VX"
  encodingCoordinates(2) = Array(20.3701125, 2.782234375, 20.3701, 2.78221875, 20.370125, 2.78225)
  encodingCodes(3) = "7FG49QCJ+2VXGJ"
  encodingCoordinates(3) = Array(20.3701135, 2.78223535156, 20.370113, 2.782234375, 20.370114, 2.78223632813)
  encodingCodes(4) = "8FVC2222+22"
  encodingCoordinates(4) = Array(47.0000625, 8.0000625, 47, 8, 47.000125, 8.000125)
  encodingCodes(5) = "4VCPPQGP+Q9"
  encodingCoordinates(5) = Array(-41.2730625, 174.7859375, -41.273125, 174.785875, -41.273, 174.786)
  encodingCodes(6) = "62G20000+"
  encodingCoordinates(6) = Array(0.5, -179.5, 0, -180, 1, -179)
  encodingCodes(7) = "22220000+"
  encodingCoordinates(7) = Array(-89.5, -179.5, -90, -180, -89, -179)
  encodingCodes(8) = "7FG40000+"
  encodingCoordinates(8) = Array(20.5, 2.5, 20, 2, 21, 3#)
  encodingCodes(9) = "22222222+22"
  encodingCoordinates(9) = Array(-89.9999375, -179.9999375, -90, -180, -89.999875, -179.999875)
  encodingCodes(10) = "6VGX0000+"
  encodingCoordinates(10) = Array(0.5, 179.5, 0, 179, 1, 180)
  encodingCodes(11) = "CFX30000+"
  encodingCoordinates(11) = Array(90, 1, 89, 1, 90, 2)
  encodingCodes(12) = "CFX30000+"
  encodingCoordinates(12) = Array(92, 1, 89, 1, 90, 2)
  encodingCodes(13) = "62H20000+"
  encodingCoordinates(13) = Array(1, 180, 1, -180, 2, -179)
  encodingCodes(14) = "62H30000+"
  encodingCoordinates(14) = Array(1, 181, 1, -179, 2, -178)
  For i = 0 To 13
    a = OLCDecode(encodingCodes(i))
    c = OLCEncode(encodingCoordinates(i)(0), encodingCoordinates(i)(1), a.CodeLength)
    If c <> Ucase(encodingCodes(i)) Then
      MsgBox ("Encoding test " + CStr(i) + ", code generation expected: " + encodingCodes(i) + ", actual: " + c)
      Exit Sub
    End If
    c = OLCEncode(a.LatCenter, a.LngCenter, a.CodeLength)
    If c <> Ucase(encodingCodes(i)) Then
      MsgBox ("Encoding test " + CStr(i) + ", code recovery expected: " + encodingCodes(i) + ", actual: " + c)
      Exit Sub
    End If
    If Not doubleEquals(a.LatLo, encodingCoordinates(i)(2)) Or Not doubleEquals(a.LngLo, encodingCoordinates(i)(3)) Or Not doubleEquals(a.LatHi, encodingCoordinates(i)(4)) Or Not doubleEquals(a.LngHi, encodingCoordinates(i)(5)) Then
      MsgBox ("Encoding test " + CStr(i) + " failed coordinate check: " + CStr(a.LatLo) + "," + CStr(a.LngLo) + " " + CStr(a.LatHi) + "," + CStr(a.LngHi) + _
         " expected: " + CStr(encodingCoordinates(i)(2)) + "," + CStr(encodingCoordinates(i)(3)) + " " + CStr(encodingCoordinates(i)(4)) + "," + CStr(encodingCoordinates(i)(5)))
      Exit Sub
    End If
  Next

  Dim shortCodes(11) As Variant
  shortCodes(0) = Array("9C3W9QCJ+2VX", "+2VX")
  shortCodes(1) = Array("9C3W9QCJ+2VX", "CJ+2VX")
  shortCodes(2) = Array("9C3W9QCJ+2VX", "CJ+2VX")
  shortCodes(3) = Array("9C3W9QCJ+2VX", "CJ+2VX")
  shortCodes(4) = Array("9C3W9QCJ+2VX", "CJ+2VX")
  shortCodes(5) = Array("9C3W9QCJ+2VX", "9QCJ+2VX")
  shortCodes(6) = Array("9C3W9QCJ+2VX", "9QCJ+2VX")
  shortCodes(7) = Array("9C3W9QCJ+2VX", "9QCJ+2VX")
  shortCodes(8) = Array("9C3W9QCJ+2VX", "9QCJ+2VX")
  shortCodes(9) = Array("8FJFW222+", "22+")
  shortCodes(10) = Array("796RXG22+", "22+")
  Dim shortCoordinates(11) As Variant
  shortCoordinates(0) = Array(51.3701125, -1.217765625)
  shortCoordinates(1) = Array(51.3708675, -1.217765625)
  shortCoordinates(2) = Array(51.3693575, -1.217765625)
  shortCoordinates(3) = Array(51.3701125, -1.218520625)
  shortCoordinates(4) = Array(51.3701125, -1.217010625)
  shortCoordinates(5) = Array(51.3852125, -1.217765625)
  shortCoordinates(6) = Array(51.3550125, -1.217765625)
  shortCoordinates(7) = Array(51.3701125, -1.232865625)
  shortCoordinates(8) = Array(51.3701125, -1.202665625)
  shortCoordinates(9) = Array(42.899, 9.012)
  shortCoordinates(10) = Array(14.95125, -23.5001)
  For i = 0 To 10
    c = OLCShorten(shortCodes(i)(0), shortCoordinates(i)(0), shortCoordinates(i)(1))
    If c <> shortCodes(i)(1) Then
      MsgBox ("Shorten test " + CStr(i) + ", expected: " + shortCodes(i)(1) + ", actual: " + c)
      Exit Sub
    End If
    c = OLCRecoverNearest(shortCodes(i)(1), shortCoordinates(i)(0), shortCoordinates(i)(1))
    If c <> shortCodes(i)(0) Then
      MsgBox ("Recover test " + CStr(i) + ", expected: " + shortCodes(i)(0) + ", actual: " + c)
      Exit Sub
    End If
  Next

  ' North pole recovery test.
  c = OLCRecoverNearest("2222+22", 89.6, 0.0)
  If c <> "CFX22222+22" Then
    MsgBox ("North pole recovery test, expected: CFX22222+22, actual: " + c)
    Exit Sub
  End If
  ' South pole recovery test.
  c = OLCRecoverNearest("XXXXXX+XX", -81.0, 0.0)
  If c <> "2CXXXXXX+XX" Then
    MsgBox ("South pole recovery test, expected: 2CXXXXXX+XX, actual: " + c)
    Exit Sub
  End If

  MsgBox ("All tests pass")
End Sub
