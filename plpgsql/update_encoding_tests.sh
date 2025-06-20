#!/bin/bash
set -e
# Re-create the test_encoding.sql script using updated tests.
# Pass the location of the test_data/encoding.csv file.

CSV_FILE=$1
if ! [ -f "$CSV_FILE" ]; then
    echo First parameter must be to the encoding CSV file with the test data.
    exit 1
fi

SQL_TEST=test_encoding.sql
if ! [ -f "$SQL_TEST" ]; then
    echo "$SQL_TEST" must be in the current directory
    exit 1
fi

# Overwrite the test file with the exception function and the table definition.
cat <<EOF >"$SQL_TEST"
-- Encoding function tests for PostgreSQL.

-- If the encoding.csv file located at
-- https://github.com/google/open-location-code/blob/main/test_data/encoding.csv
-- is updated, run the update_encoding_tests.sh script.

-- RAISE is not supported directly in SELECT statements, it must be called from a function.
CREATE FUNCTION raise_error(msg text) RETURNS integer
LANGUAGE plpgsql AS
\$\$BEGIN
RAISE EXCEPTION '%', msg;
RETURN 42;
END;\$\$;

CREATE TABLE encoding_tests (
    latitude_degrees NUMERIC NOT NULL,
    longitude_degrees NUMERIC NOT NULL,
    latitude_integer BIGINT NOT NULL,
    longitude_integer BIGINT NOT NULL,
    code_length INTEGER NOT NULL,
    code TEXT NOT NULL
);
EOF

# Now get the test data and reformat it.
# IFS (Internal Field Separator) is set to comma to split fields correctly.
# -r prevents backslash escapes from being interpreted.
while IFS=',' read -r latd lngd lati lngi len code || [[ -n "$code" ]]; do
    # Skip lines that start with '#' (comments in the CSV file)
    if [[ "$latd" =~ ^# ]]; then
        continue
    fi
    # Skip empty lines
    if [ -z "$latd" ]; then
        continue
    fi

    # Construct the SQL INSERT statement
    # Numeric fields are inserted directly.
    # Text field (code) is enclosed in single quotes.
    echo "INSERT INTO encoding_tests VALUES (${latd}, ${lngd}, ${lati}, ${lngi}, ${len}, '${code}');"

done < "$CSV_FILE" >>"$SQL_TEST"

# Now add the SELECT statement that calls the functions and checks the output.
cat <<EOF >>"$SQL_TEST"

-- The subselect in the FROM clause calls the functions, the outer SELECT checks the results.
SELECT
  CASE
    WHEN latitude_integer <> latitude_integer_got
    THEN raise_error(format('Row %s: latitudeToInteger(%s): got %s, want %s', ROW_NUMBER() OVER (), latitude_degrees, latitude_integer_got, latitude_integer))
    ELSE ROW_NUMBER() OVER ()
  END AS latitudeToInteger,
  CASE
    WHEN longitude_integer <> longitude_integer_got
    THEN raise_error(format('Row %s: longitudeToInteger(%s): got %s, want %s', ROW_NUMBER() OVER (), longitude_degrees, longitude_integer_got, longitude_integer))
    ELSE ROW_NUMBER() OVER ()
  END AS longitudeToInteger,
  CASE
    WHEN code <> code_got
    THEN raise_error(format('Row %s: encodeIntegers(%s, %s, %s): got %s, want %s', ROW_NUMBER() OVER (), latitude_integer, longitude_integer, code_length, code_got, code))
    ELSE ROW_NUMBER() OVER ()
  END AS encodeIntegers
FROM (
  SELECT
    *,
    pluscode_latitudeToInteger(latitude_degrees) AS latitude_integer_got,
    pluscode_longitudeToInteger(longitude_degrees) longitude_integer_got,
    pluscode_encodeIntegers(latitude_integer, longitude_integer, code_length) AS code_got
  FROM encoding_tests
) AS test_data;
EOF