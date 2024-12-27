-- Pluscode implementation for PostgreSQL
--
--
-- Licensed under the Apache License, Version 2.0 (the 'License');
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
-- http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an 'AS IS' BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--
--


-- pluscode_cliplatitude ####
-- Clip latitude between -90 and 90 degrees.
-- PARAMETERS
-- lat numeric // latitude to use for the reference location
-- EXAMPLE
-- select pluscode_cliplatitude(149.18);
CREATE OR REPLACE FUNCTION public.pluscode_cliplatitude(
    lat numeric)
RETURNS numeric
    LANGUAGE 'plpgsql'
    COST 100
    IMMUTABLE
AS $BODY$
BEGIN
    IF lat < -90 THEN
        RETURN -90;
    END IF;
    IF lat > 90 THEN
        RETURN 90;
    ELSE
        RETURN lat;
    END IF;
END;
$BODY$;


-- -- pluscode_computeLatitudePrecision ####
-- -- Compute the latitude precision value for a given code length.
-- -- PARAMETERS
-- -- codeLength int // How long must be the pluscode
-- -- EXAMPLE
-- -- select pluscode_computeLatitudePrecision(11);
CREATE OR REPLACE FUNCTION public.pluscode_computeLatitudePrecision(
    codeLength int)
RETURNS numeric
    LANGUAGE 'plpgsql'
    COST 100
    IMMUTABLE
AS $BODY$
DECLARE
    CODE_ALPHABET_ text := '23456789CFGHJMPQRVWX';
    ENCODING_BASE_ int := char_length(CODE_ALPHABET_);
    PAIR_CODE_LENGTH_ int := 10;
    GRID_ROWS_ int := 5;
BEGIN
    IF (codeLength <= PAIR_CODE_LENGTH_) THEN
        RETURN power(ENCODING_BASE_, floor((codeLength / (-2)) + 2));
    ELSE
        RETURN power(ENCODING_BASE_, -3) / power(GRID_ROWS_, codeLength - PAIR_CODE_LENGTH_);
    END IF;
END;
$BODY$;


-- pluscode_normalizelongitude ####
-- Normalize a longitude between -180 and 180 degrees (180 excluded).
-- PARAMETERS
-- lng numeric // longitude to use for the reference location
-- EXAMPLE
-- select pluscode_normalizelongitude(188.18);
CREATE OR REPLACE FUNCTION public.pluscode_normalizelongitude(
    lng numeric)
RETURNS numeric
    LANGUAGE 'plpgsql'
    COST 100
    IMMUTABLE
AS $BODY$
BEGIN
    WHILE (lng < -180) LOOP
      lng := lng + 360;
    END LOOP;
    WHILE (lng >= 180) LOOP
      lng := lng - 360;
    END LOOP;
    return lng;
END;
$BODY$;


-- pluscode_isvalid ####
-- Check if the code is valid
-- PARAMETERS
-- code text // a pluscode
-- EXAMPLE
-- select pluscode_isvalid('XX5JJC23+00');
CREATE OR REPLACE FUNCTION public.pluscode_isvalid(
    code text)
RETURNS boolean
    LANGUAGE 'plpgsql'
    COST 100
    IMMUTABLE
AS $BODY$
DECLARE
separator_ text := '+';
separator_position int := 8;
padding_char text:= '0';
padding_int_pos integer:=0;
padding_one_int_pos integer:=0;
stripped_code text := replace(replace(code,'0',''),'+','');
code_alphabet_ text := '23456789CFGHJMPQRVWX';
idx int := 1;
BEGIN
code := code::text;
--Code Without "+" char
IF (POSITION(separator_ in code) = 0) THEN
    RETURN FALSE;
END IF;
--Code beginning with "+" char
IF (POSITION(separator_ in code) = 1) THEN
    RETURN FALSE;
END IF;
--Code with illegal position separator
IF ( (POSITION(separator_ in code) > separator_position+1) OR ((POSITION(separator_ in code)-1) % 2 = 1)  ) THEN
      RETURN FALSE;
END IF;
--Code contains padding characters "0"
IF (POSITION(padding_char in code) > 0) THEN
    IF (POSITION(separator_ in code) < 9) THEN
        RETURN FALSE;
    END IF;
    IF (POSITION(separator_ in code) = 1) THEN
        RETURN FALSE;
    END IF;
    --Check if there are many "00" groups (only one is legal)
    padding_int_pos := (select ROW_NUMBER() OVER( ORDER BY REGEXP_MATCHES(code,'('||padding_char||'+)' ,'g') ) order by 1 DESC limit 1);
    padding_one_int_pos := char_length( (select REGEXP_MATCHES(code,'('||padding_char||'+)' ,'g')  limit 1)[1] );
    IF (padding_int_pos > 1 ) THEN
        RETURN FALSE;
    END IF;
    --Check if the first group is % 2 = 0
    IF ((padding_one_int_pos % 2) = 1 ) THEN
        RETURN FALSE;
    END IF;
    --Lastchar is a separator
    IF (RIGHT(code,1) <> separator_) THEN
        RETURN FALSE;
    END IF;
END IF;
--If there is just one char after '+'
IF (char_length(code) - POSITION(separator_ in code) = 1 ) THEN
    RETURN FALSE;
END IF;
--Check if each char is in code_alphabet_
FOR i IN 1..char_length(stripped_code) LOOP
    IF (POSITION( UPPER(substring(stripped_code from i for 1)) in code_alphabet_ ) = 0) THEN
        RETURN FALSE;
    END IF;
END LOOP;
RETURN TRUE;
END;
$BODY$;


-- pluscode_codearea ####
-- Coordinates of a decoded pluscode.
-- PARAMETERS
-- latitudelo numeric // lattitude low of the pluscode
-- longitudelo numeric // longitude low of the pluscode
-- latitudehi numeric // lattitude high of the pluscode
-- longitudehi numeric // longitude high of the pluscode
-- codelength integer // length of the pluscode
-- EXAMPLE
-- select pluscode_codearea(49.1805,-0.378625,49.180625,-0.3785,10::int);
CREATE OR REPLACE FUNCTION public.pluscode_codearea(
    latitudelo numeric,
    longitudelo numeric,
    latitudehi numeric,
    longitudehi numeric,
    codelength integer)
RETURNS TABLE(lat_lo numeric, lng_lo numeric, lat_hi numeric, lng_hi numeric, code_length numeric, lat_center numeric, lng_center numeric)
    LANGUAGE 'plpgsql'
    COST 100
    IMMUTABLE
    ROWS 1000
AS $BODY$
DECLARE
    rlatitudeLo numeric:= latitudeLo;
    rlongitudeLo numeric:= longitudeLo;
    rlatitudeHi numeric:= latitudeHi;
    rlongitudeHi numeric:= longitudeHi;
    rcodeLength numeric:= codeLength;
    rlatitudeCenter numeric:= 0;
    rlongitudeCenter numeric:= 0;
    latitude_max_ int:= 90;
    longitude_max_ int:= 180;
BEGIN
    --calculate the latitude center
    IF (((latitudeLo + (latitudeHi - latitudeLo))/ 2) > latitude_max_) THEN
        rlatitudeCenter := latitude_max_;
    ELSE
        rlatitudeCenter := (latitudeLo + (latitudeHi - latitudeLo)/ 2);
    END IF;
    --calculate the longitude center
    IF (((longitudeLo + (longitudeHi - longitudeLo))/ 2) > longitude_max_) THEN
        rlongitudeCenter := longitude_max_;
    ELSE
        rlongitudeCenter := (longitudeLo + (longitudeHi - longitudeLo)/ 2);
    END IF;

    RETURN QUERY SELECT
        rlatitudeLo::double precision::numeric as lat_lo,
        rlongitudeLo::double precision::numeric as lng_lo,
        rlatitudeHi::double precision::numeric as lat_hi,
        rlongitudeHi::double precision::numeric as lng_hi,
        rcodeLength as code_length,
        rlatitudeCenter::double precision::numeric,
        rlongitudeCenter::double precision::numeric;
END;
$BODY$;


-- pluscode_isshort ####
-- Check if the code is a short version of a pluscode
-- PARAMETERS
-- code text // a valid pluscode
-- EXAMPLE
-- select pluscode_isshort('XX5JJC+');
CREATE OR REPLACE FUNCTION public.pluscode_isshort(
    code text)
RETURNS boolean
    LANGUAGE 'plpgsql'
    COST 100
    IMMUTABLE
AS $BODY$
DECLARE
separator_ text := '+';
separator_position int := 9;
BEGIN
    -- the pluscode is valid ?
    IF (pluscode_isvalid(code)) is FALSE THEN
        RETURN FALSE;
    END IF;
    -- the pluscode contain a '+' at a correct place
    IF ((POSITION(separator_ in code)>0) AND (POSITION(separator_ in code)< separator_position)) THEN
        RETURN TRUE;
    END IF;
RETURN FALSE;
END;
$BODY$;


-- pluscode_isfull ####
-- Is the codeplus a full code
-- PARAMETERS
-- code text // codeplus
-- EXAMPLE
-- select pluscode_isfull('cccccc+')
CREATE OR REPLACE FUNCTION public.pluscode_isfull(
    code text)
RETURNS boolean
    LANGUAGE 'plpgsql'
    COST 100
    IMMUTABLE
AS $BODY$
DECLARE
code_alphabet text := '23456789CFGHJMPQRVWX';
first_lat_val int:= 0;
first_lng_val int:= 0;
encoding_base_ int := char_length(code_alphabet);
latitude_max_ int := 90;
longitude_max_ int := 180;
BEGIN
    IF (pluscode_isvalid(code)) is FALSE THEN
        RETURN FALSE;
    END IF;
    -- If is short --> not full.
    IF (pluscode_isshort(code)) is TRUE THEN
        RETURN FALSE;
    END IF;
    --Check latitude for first lat char
    first_lat_val := (POSITION( UPPER(LEFT(code,1)) IN  code_alphabet  )-1) * encoding_base_;
    IF (first_lat_val >= latitude_max_ * 2) THEN
        RETURN FALSE;
    END IF;
    IF (char_length(code) > 1) THEN
        --Check longitude for first lng char
        first_lng_val := (POSITION( UPPER(SUBSTRING(code FROM 2 FOR 1)) IN  code_alphabet)-1) * encoding_base_;
        IF (first_lng_val >= longitude_max_ *2) THEN
            RETURN FALSE;
        END IF;
    END IF;
    RETURN TRUE;
END;
$BODY$;


-- pluscode_encode ####
-- Encode lat lng to get pluscode
-- PARAMETERS
-- latitude numeric // latitude ref
-- longitude numeric // longitude ref
-- codeLength int// How long must be the pluscode
-- EXAMPLE
-- select pluscode_encode(49.05,-0.108,12);
CREATE OR REPLACE FUNCTION public.pluscode_encode(
    latitude numeric,
    longitude numeric,
    codeLength int DEFAULT 10)
RETURNS text
    LANGUAGE 'plpgsql'
    COST 100
    IMMUTABLE
AS $BODY$
DECLARE
    SEPARATOR_ text := '+';
    SEPARATOR_POSITION_ int := 8;
    PADDING_CHARACTER_ text := '0';
    CODE_ALPHABET_ text := '23456789CFGHJMPQRVWX';
    ENCODING_BASE_ int := char_length(CODE_ALPHABET_);
    LATITUDE_MAX_ int := 90;
    LONGITUDE_MAX_ int := 180;
    MIN_DIGIT_COUNT_ int := 2;
    MAX_DIGIT_COUNT_ int := 15;
    PAIR_CODE_LENGTH_ int := 10;
    PAIR_PRECISION_ decimal := power(ENCODING_BASE_, 3);
    GRID_CODE_LENGTH_ int := MAX_DIGIT_COUNT_ - PAIR_CODE_LENGTH_;
    GRID_COLUMNS_ int := 4;
    GRID_ROWS_ int := 5;
    FINAL_LAT_PRECISION_ decimal := PAIR_PRECISION_ * power(GRID_ROWS_, MAX_DIGIT_COUNT_ - PAIR_CODE_LENGTH_);
    FINAL_LNG_PRECISION_ decimal := PAIR_PRECISION_ * power(GRID_COLUMNS_, MAX_DIGIT_COUNT_ - PAIR_CODE_LENGTH_);
    code text := '';
    latVal decimal := 0;
    lngVal decimal := 0;
    latDigit smallint;
    lngDigit smallint;
    ndx smallint;
    i_ smallint;
BEGIN
    IF ((codeLength < MIN_DIGIT_COUNT_) OR ((codeLength < PAIR_CODE_LENGTH_) AND (codeLength % 2 = 1))) THEN
        RAISE EXCEPTION 'Invalid Open Location Code length - %', codeLength
        USING HINT = 'The Open Location Code length must be 2, 4, 6, 8, 10, 11, 12, 13, 14, or 15.';
    END IF;

    codeLength := LEAST(codeLength, MAX_DIGIT_COUNT_);

    latitude := pluscode_clipLatitude(latitude);
    longitude := pluscode_normalizeLongitude(longitude);

    IF (latitude = 90) THEN
        latitude := latitude - pluscode_computeLatitudePrecision(codeLength);
    END IF;

    latVal := floor(round((latitude + LATITUDE_MAX_) * FINAL_LAT_PRECISION_, 6));
    lngVal := floor(round((longitude + LONGITUDE_MAX_) * FINAL_LNG_PRECISION_, 6));

    IF (codeLength > PAIR_CODE_LENGTH_) THEN
        i_ := 0;
        WHILE (i_ < (MAX_DIGIT_COUNT_ - PAIR_CODE_LENGTH_)) LOOP
            latDigit := latVal % GRID_ROWS_;
            lngDigit := lngVal % GRID_COLUMNS_;
            ndx := (latDigit * GRID_COLUMNS_) + lngDigit;
            code := substr(CODE_ALPHABET_, ndx + 1, 1) || code;
            latVal := div(latVal, GRID_ROWS_);
            lngVal := div(lngVal, GRID_COLUMNS_);
            i_ := i_ + 1;
        END LOOP;
    ELSE
        latVal := div(latVal, power(GRID_ROWS_, GRID_CODE_LENGTH_)::integer);
        lngVal := div(lngVal, power(GRID_COLUMNS_, GRID_CODE_LENGTH_)::integer);
    END IF;

    i_ := 0;
    WHILE (i_ < (PAIR_CODE_LENGTH_ / 2)) LOOP
        code := substr(CODE_ALPHABET_, (lngVal % ENCODING_BASE_)::integer + 1, 1) || code;
        code := substr(CODE_ALPHABET_, (latVal % ENCODING_BASE_)::integer + 1, 1) || code;
        latVal := div(latVal, ENCODING_BASE_);
        lngVal := div(lngVal, ENCODING_BASE_);
        i_ := i_ + 1;
    END LOOP;

    code := substr(code, 1, SEPARATOR_POSITION_) || SEPARATOR_ || substr(code, SEPARATOR_POSITION_ + 1);

    IF (codeLength >= SEPARATOR_POSITION_) THEN
        RETURN substr(code, 1, codeLength + 1);
    ELSE
        RETURN rpad(substr(code, 1, codeLength), SEPARATOR_POSITION_, PADDING_CHARACTER_) || SEPARATOR_;
    END IF;
END;
$BODY$;


-- pluscode_decode ####
-- Decode a pluscode to get the corresponding bounding box and the center
-- PARAMETERS
-- code text// the pluscode to decode
-- EXAMPLE
-- select pluscode_decode('CCCCCCCC+');
CREATE OR REPLACE FUNCTION public.pluscode_decode(
    code text)
RETURNS TABLE(lat_lo numeric, lng_lo numeric, lat_hi numeric, lng_hi numeric, code_length numeric, lat_center numeric, lng_center numeric)
    LANGUAGE 'plpgsql'
    COST 100
    IMMUTABLE
    ROWS 1000
AS $BODY$
DECLARE
lat_out float := 0;
lng_out float := 0;
latitude_max_ int := 90;
longitude_max_ int := 180;
lat_precision numeric := 0;
lng_precision numeric:= 0;
code_alphabet text := '23456789CFGHJMPQRVWX';
stripped_code text := UPPER(replace(replace(code,'0',''),'+',''));
encoding_base_ int := char_length(code_alphabet);
pair_precision_ numeric := power(encoding_base_::double precision, 3::double precision);
normal_lat numeric:= -latitude_max_ * pair_precision_;
normal_lng numeric:= -longitude_max_ * pair_precision_;
grid_lat_ numeric:= 0;
grid_lng_ numeric:= 0;
max_digit_count_ int:= 15;
pair_code_length_ int:=10;
digits int:= 0;
pair_first_place_value_ numeric:= power(encoding_base_, (pair_code_length_/2)-1);
pv int:= 0;
iterator int:=0;
iterator_d int:=0;
digit_val int := 0;
row_ numeric := 0;
col_ numeric := 0;
return_record record;
grid_code_length_ int:= max_digit_count_ - pair_code_length_;
grid_columns_ int := 4;
grid_rows_  int := 5;
grid_lat_first_place_value_ int := power(grid_rows_, (grid_code_length_ - 1));
grid_lng_first_place_value_ int := power(grid_columns_, (grid_code_length_ - 1));
final_lat_precision_ numeric := pair_precision_ * power(grid_rows_, (max_digit_count_ - pair_code_length_));
final_lng_precision_ numeric := pair_precision_ * power(grid_columns_, (max_digit_count_ - pair_code_length_));
rowpv numeric := grid_lat_first_place_value_;
colpv numeric := grid_lng_first_place_value_;

BEGIN
    IF (pluscode_isfull(code)) is FALSE THEN
        RAISE EXCEPTION 'NOT A VALID FULL CODE: %', code;
    END IF;
    --strip 0 and + chars
    code:= stripped_code;
    normal_lat := -latitude_max_ * pair_precision_;
    normal_lng := -longitude_max_ * pair_precision_;

    --how many digits must be used
    IF (char_length(code) > pair_code_length_) THEN
        digits := pair_code_length_;
    ELSE
        digits := char_length(code);
    END IF;
    pv := pair_first_place_value_;
    WHILE iterator < digits
        LOOP
            normal_lat := normal_lat + (POSITION( SUBSTRING(code FROM iterator+1 FOR 1) IN code_alphabet)-1 )* pv;
            normal_lng := normal_lng + (POSITION( SUBSTRING(code FROM iterator+1+1 FOR 1) IN code_alphabet)-1  ) * pv;
            IF (iterator < (digits -2)) THEN
                pv := pv/encoding_base_;
            END IF;
            iterator := iterator + 2;

        END LOOP;

    --convert values to degrees
    lat_precision := pv/ pair_precision_;
    lng_precision := pv/ pair_precision_;

    IF (char_length(code) > pair_code_length_) THEN
        IF (char_length(code) > max_digit_count_) THEN
            digits := max_digit_count_;
        ELSE
            digits := char_length(code);
        END IF;
        iterator_d := pair_code_length_;
        WHILE iterator_d < digits
        LOOP
            digit_val := (POSITION( SUBSTRING(code FROM iterator_d+1 FOR 1) IN code_alphabet)-1);
            row_ := ceil(digit_val/grid_columns_);
            col_ := digit_val % grid_columns_;
            grid_lat_ := grid_lat_ +(row_*rowpv);
            grid_lng_ := grid_lng_ +(col_*colpv);
            IF ( iterator_d < (digits -1) ) THEN
                rowpv := rowpv / grid_rows_;
                colpv := colpv / grid_columns_;
            END IF;
            iterator_d := iterator_d + 1;
        END LOOP;
        --adjust precision
        lat_precision := rowpv / final_lat_precision_;
        lng_precision := colpv / final_lng_precision_;
    END IF;

    --merge the normal and extra precision of the code
    lat_out := normal_lat / pair_precision_ + grid_lat_ / final_lat_precision_;
    lng_out := normal_lng / pair_precision_ + grid_lng_ / final_lng_precision_;

    IF (char_length(code) > max_digit_count_ ) THEN
        digits := max_digit_count_;
        RAISE NOTICE 'lat_out max_digit_count_ %', lat_out;
    ELSE
        digits := char_length(code);
        RAISE NOTICE 'digits char_length%', digits;
    END IF ;

    return_record := pluscode_codearea(
            lat_out::numeric,
            lng_out::numeric,
            (lat_out+lat_precision)::numeric,
            (lng_out+lng_precision)::numeric,
            digits::int
    );
    RETURN QUERY SELECT
        return_record.lat_lo,
        return_record.lng_lo,
        return_record.lat_hi,
        return_record.lng_hi,
        return_record.code_length,
        return_record.lat_center,
        return_record.lng_center
    ;
END;
$BODY$;


-- pluscode_shorten ####
-- Remove characters from the start of an OLC code.
-- PARAMETERS
-- code text //full code
-- latitude numeric //latitude to use for the reference location
-- longitude numeric //longitude to use for the reference location
-- EXAMPLE
-- select pluscode_shorten('8CXX5JJC+6H6H6H',49.18,-0.37);
CREATE OR REPLACE FUNCTION public.pluscode_shorten(
    code text,
    latitude numeric,
    longitude numeric)
RETURNS text
    LANGUAGE 'plpgsql'
    COST 100
    IMMUTABLE
AS $BODY$
DECLARE
padding_character text :='0';
code_area record;
min_trimmable_code_len int:= 6;
range_ numeric:= 0;
lat_dif numeric:= 0;
lng_dif numeric:= 0;
pair_resolutions_ FLOAT[] := ARRAY[20.0, 1.0, 0.05, 0.0025, 0.000125]::FLOAT[];
iterator int:= 0;
BEGIN
    IF (pluscode_isfull(code)) is FALSE THEN
        RAISE EXCEPTION 'Code is not full and valid: %', code;
    END IF;

    IF (POSITION(padding_character IN code) > 0) THEN
      RAISE EXCEPTION 'Code contains 0 character(s), not valid : %', code;
    END IF;

    code := UPPER(code);
    code_area := pluscode_decode(code);

    IF (code_area.code_length < min_trimmable_code_len ) THEN
        RAISE EXCEPTION 'Code must contain more than 6 character(s) : %',code;
    END IF;

    --Are the latitude and longitude valid
    IF (pg_typeof(latitude) NOT IN ('numeric','real','double precision','integer','bigint','float')) OR (pg_typeof(longitude) NOT IN ('numeric','real','double precision','integer','bigint','float')) THEN
        RAISE EXCEPTION 'LAT || LNG are not numbers % !',pg_typeof(latitude)||' || '||pg_typeof(longitude);
    END IF;

    latitude := pluscode_clipLatitude(latitude);
    longitude := pluscode_normalizelongitude(longitude);

    lat_dif := ABS(code_area.lat_center - latitude);
    lng_dif := ABS(code_area.lng_center - longitude);

    --calculate max distance with the center
    IF (lat_dif > lng_dif) THEN
        range_ := lat_dif;
    ELSE
        range_ := lng_dif;
    END IF;

    iterator := ARRAY_LENGTH( pair_resolutions_, 1)-2;

    WHILE ( iterator >= 1 )
    LOOP
        --is it close enough to shortent the code ?
        --use 0.3 for safety instead of 0.5
        IF ( range_ < (pair_resolutions_[ iterator ]*0.3) ) THEN
            RETURN SUBSTRING( code , ((iterator+1)*2)-1 );
        END IF;
        iterator := iterator - 1;
    END LOOP;
RETURN code;
END;
$BODY$;


-- pluscode_recovernearest ####
-- Retrieve a valid full code (the nearest from lat/lng).
-- PARAMETERS
-- short_code text // a valid shortcode
-- reference_latitude numeric // a valid latitude
-- reference_longitude numeric // a valid longitude
-- EXAMPLE
-- select pluscode_recovernearest('XX5JJC+', 49.1805,-0.3786);
CREATE OR REPLACE FUNCTION public.pluscode_recovernearest(
    short_code text,
    reference_latitude numeric,
    reference_longitude numeric)
RETURNS text
    LANGUAGE 'plpgsql'
    COST 100
    IMMUTABLE
AS $BODY$
DECLARE
padding_length int :=0;
separator_position_ int := 8;
separator_ text := '+';
resolution int := 0;
half_resolution numeric := 0;
code_area record;
latitude_max int := 90;
code_out text := '';
BEGIN

    IF (pluscode_isshort(short_code)) is FALSE THEN
        IF (pluscode_isfull(short_code)) THEN
            RETURN UPPER(short_code);
        ELSE
            RAISE EXCEPTION 'Short code is not valid: %', short_code;
        END IF;
        RAISE EXCEPTION 'NOT A VALID FULL CODE: %', code;
    END IF;

    --Are the latitude and longitude valid
    IF (pg_typeof(reference_latitude) NOT IN ('numeric','real','double precision','integer','bigint','float')) OR (pg_typeof(reference_longitude) NOT IN ('numeric','real','double precision','integer','bigint','float')) THEN
        RAISE EXCEPTION 'LAT || LNG are not numbers % !',pg_typeof(latitude)||' || '||pg_typeof(longitude);
    END IF;

    reference_latitude := pluscode_clipLatitude(reference_latitude);
    reference_longitude := pluscode_normalizeLongitude(reference_longitude);

    short_code := UPPER(short_code);
    -- Calculate the number of digits to recover.
    padding_length := separator_position_ - POSITION(separator_ in short_code)+1;
    -- Calculate the resolution of the padded area in degrees.
    resolution := power(20, 2 - (padding_length / 2));
    -- Half resolution for difference with the center
    half_resolution := resolution / 2.0;

    -- Concatenate short_code and the calculated value --> encode(lat,lng)
    code_area := pluscode_decode(SUBSTRING(pluscode_encode(reference_latitude::numeric, reference_longitude::numeric) , 1 , padding_length) || short_code);

    --Check if difference with the center is more than half_resolution
    --Keep value between -90 and 90
    IF (((reference_latitude + half_resolution) < code_area.lat_center) AND ((code_area.lat_center - resolution) >= -latitude_max)) THEN
        code_area.lat_center := code_area.lat_center - resolution;
    ELSIF (((reference_latitude - half_resolution) > code_area.lat_center) AND ((code_area.lat_center + resolution) <= latitude_max)) THEN
      code_area.lat_center := code_area.lat_center + resolution;
    END IF;

    -- difference with the longitude reference
    IF (reference_longitude + half_resolution < code_area.lng_center ) THEN
      code_area.lng_center := code_area.lng_center - resolution;
    ELSIF (reference_longitude - half_resolution > code_area.lng_center) THEN
      code_area.lng_center := code_area.lng_center + resolution;
    END IF;

    code_out := pluscode_encode(code_area.lat_center::numeric, code_area.lng_center::numeric, code_area.code_length::integer);

RETURN code_out;
END;
$BODY$;
