#!/bin/bash
set -e
# Re-create the OLCTests.bas script using updated tests.

VBA_TEST=OLCTests.bas
if ! [ -f "$VBA_TEST" ]; then
    echo "$VBA_TEST" must be in the current directory
    exit 1
fi

# This function writes a VB function with the test cases from the file encoding.csv
# Each line will add a test case to the array named in the first argument, and
function addEncodingTests() {
    TEST_CASE_COUNTER=0
    STATEMENTS=""
    while IFS=',' read -r latd lngd lati lngi len code || [[ -n "$code" ]]; do
        # Skip lines that start with '#' (comments in the CSV file)
        if [[ "$latd" =~ ^# ]]; then
            continue
        fi
        # Skip empty lines
        if [ -z "$latd" ]; then
            continue
        fi
        STATEMENTS="$STATEMENTS    testCases(${TEST_CASE_COUNTER}) = Array(${latd}, ${lngd}, ${lati}, ${lngi}, ${len}, \"${code}\")\n"
        TEST_CASE_COUNTER=$((TEST_CASE_COUNTER+1))
    done < ../test_data/encoding.csv

    # Add the VB function.
    echo -e "Private Function loadEncodingTestCSV() AS Variant\n\n    Dim testCases(${TEST_CASE_COUNTER}) As Variant" >>"$VBA_TEST"
    # Add all the statments that populate the test data array.
    echo -e "${STATEMENTS}" >>"$VBA_TEST"
    echo -e "    loadEncodingTestCSV = testCases\nEnd Function" >>"$VBA_TEST"

    # Add tests that use the encoding CSV data.
    cat <<EOF >>"$VBA_TEST"

' Check the degrees to integer conversions.
Sub TEST_IntegerConversion()
    Dim encodingTests As Variant
    Dim i As Integer
    Dim tc As Variant
    Dim degrees AS Double
    Dim got_integer As Double
    Dim want_integer As Double

    encodingTests = loadEncodingTestCSV()

    For i = 0 To ${TEST_CASE_COUNTER}
        tc = encodingTests(i)
        degrees = tc(0)
        want_integer = tc(2)
        got_integer = latitudeToInteger(degrees)
        If got_integer <> want_integer Then
            MsgBox ("Encoding test " + CStr(i) + ": latitudeToInteger(" + CStr(degrees) + "): got " + CStr(got_integer) + ", want " + CStr(want_integer))
            Exit Sub
        End If
        degrees = tc(1)
        want_integer = tc(3)
        got_integer = longitudeToInteger(degrees)
        If got_integer <> want_integer Then
            MsgBox ("Encoding test " + CStr(i) + ": longitudeToInteger(" + CStr(degrees) + "): got " + CStr(got_integer) + ", want " + CStr(want_integer))
            Exit Sub
        End If
    Next

    MsgBox ("TEST_IntegerConversion passes")
End Sub

' Check the integer encoding.
Sub TEST_IntegerEncoding()
    Dim encodingTests As Variant
    Dim i As Integer
    Dim tc As Variant
    Dim latitude As Double
    Dim longitude As Double
    Dim code_length As Integer
    Dim want_code As String
    Dim got_code As String

    encodingTests = loadEncodingTestCSV()

    For i = 0 To ${TEST_CASE_COUNTER}
        tc = encodingTests(i)
        ' Latitude and longitude are the integer values, not degrees.
        latitude = tc(2)
        longitude = tc(3)
        code_length = tc(4)
        want_code = tc(5)
        got_code = encodeIntegers(latitude, longitude, code_length)
        If got_code <> want_code Then
            MsgBox ("Encoding test " + CStr(i) + ": encodeIntegers(" + CStr(latitude) + ", " + CStr(longitude) + ", " + CStr(code_length) + "): got " + got_code + ", want " + want_code)
            Exit Sub
        End If
    Next

    MsgBox ("TEST_IntegerEncoding passes")
End Sub
EOF
}

cat <<EOF >"$VBA_TEST"
' Code to test the VisualBasic OpenLocationCode functions.
' Copy this into your VB macro and run the TEST_All() function.

EOF

addEncodingTests

# Now add the test functions.
cat <<EOF >>"$VBA_TEST"
' This is a subroutine to test the functions of the library, using test data
' copied from the Github project. This should be migrated to being generated
' from the CSV files.
Sub TEST_OLCLibrary()
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

  MsgBox ("TEST_OLCLibrary passes")
End Sub

Sub TEST_All()
    TEST_OLCLibrary

    TEST_IntegerConversion
    TEST_IntegerEncoding
End Sub
EOF