package com.google.openlocationcode

import kotlin.jvm.JvmOverloads
import kotlin.jvm.JvmStatic
import kotlin.math.*

/**
 * Convert locations to and from convenient short codes.
 *
 * Open Location Codes are short, ~10 character codes that can be used instead of street
 * addresses. The codes can be generated and decoded offline, and use a reduced character set that
 * minimises the chance of codes including words.
 *
 * This provides both object and static methods.
 *
 * Create an object with: OpenLocationCode code = new OpenLocationCode("7JVW52GR+2V");
 * OpenLocationCode code = new OpenLocationCode("52GR+2V"); OpenLocationCode code = new
 * OpenLocationCode(27.175063, 78.042188); OpenLocationCode code = new OpenLocationCode(27.175063,
 * 78.042188, 11);
 *
 * Once you have a code object, you can apply the other methods to it, such as to shorten:
 * code.shorten(27.176, 78.05)
 *
 * Recover the nearest match (if the code was a short code): code.recover(27.176, 78.05)
 *
 * Or decode a code into its coordinates, returning a CodeArea object. code.decode()
 *
 * @author Jiri Semecky (original Java version)
 * @author Doug Rinckes (original Java version)
 * @author Jayson Minard (port to Kotlin)
 */
class OpenLocationCode(code: String) {

    /**
     * The PlusCode
     *
     * Returns the string representation of the code normalized to upper case.
     *
     * @return The code.
     */
    val code: String = code.toUpperCase().also { normalized ->
        require(isValidCode(normalized)) { "The provided code '$code' is not a valid Open Location Code." }
    }

    /**
     * Returns whether this [OpenLocationCode] is a full Open Location Code.
     *
     * @return True if it is a full code.
     */
    val isFull: Boolean by lazy(LazyThreadSafetyMode.PUBLICATION) {
        code.indexOf(SEPARATOR) == SEPARATOR_POSITION
    }

    /**
     * Returns whether this [OpenLocationCode] is a short Open Location Code.
     *
     * @return True if it is short.
     */
    val isShort: Boolean by lazy(LazyThreadSafetyMode.PUBLICATION) {
        code.indexOf(SEPARATOR) in 0 until SEPARATOR_POSITION
    }

    /**
     * Returns whether this [OpenLocationCode] is a padded Open Location Code, meaning that it
     * contains less than 8 valid digits.
     *
     * @return True if this code is padded.
     */
    val isPadded: Boolean by lazy(LazyThreadSafetyMode.PUBLICATION) {
        code.indexOf(PADDING_CHARACTER) >= 0
    }

    /**
     * Coordinates of a decoded Open Location Code.
     *
     *
     * The coordinates include the latitude and longitude of the lower left and upper right corners
     * and the center of the bounding box for the area the code represents.
     */
    data class CodeArea(
        val southLatitude: Double,
        val westLongitude: Double,
        val northLatitude: Double,
        val eastLongitude: Double,
        val length: Int
    ) {
        val latitudeHeight: Double = northLatitude - southLatitude
        val longitudeWidth: Double = eastLongitude - westLongitude
        val centerLatitude: Double = (southLatitude + northLatitude) / 2
        val centerLongitude: Double = (westLongitude + eastLongitude) / 2
    }


    /**
     * Decodes [OpenLocationCode] object into [CodeArea] object encapsulating
     * latitude/longitude bounding box.
     *
     * @return A CodeArea object.
     */
    fun decode(): CodeArea {
        check(isFullCode(code)) { "Method decode() could only be called on valid full codes, code was $code." }
        // Strip padding and separator characters out of the code.
        val clean = code.replace(SEPARATOR.toString(), "").replace(PADDING_CHARACTER.toString(), "")

        // Initialise the values. We work them out as integers and convert them to doubles at the end.
        var latVal = -LATITUDE_MAX * LAT_INTEGER_MULTIPLIER
        var lngVal = -LONGITUDE_MAX * LNG_INTEGER_MULTIPLIER
        // Define the place value for the digits. We'll divide this down as we work through the code.
        var latPlaceVal = LAT_MSP_VALUE
        var lngPlaceVal = LNG_MSP_VALUE
        run {
            var i = 0
            while (i < min(clean.length, PAIR_CODE_LENGTH)) {
                latPlaceVal /= ENCODING_BASE.toLong()
                lngPlaceVal /= ENCODING_BASE.toLong()
                latVal += CODE_ALPHABET.indexOf(clean[i]) * latPlaceVal
                lngVal += CODE_ALPHABET.indexOf(clean[i + 1]) * lngPlaceVal
                i += 2
            }
        }
        for (i in PAIR_CODE_LENGTH until min(clean.length, MAX_DIGIT_COUNT)) {
            latPlaceVal /= GRID_ROWS.toLong()
            lngPlaceVal /= GRID_COLUMNS.toLong()
            val digit = CODE_ALPHABET.indexOf(clean[i])
            val row = digit / GRID_COLUMNS
            val col = digit % GRID_COLUMNS
            latVal += row * latPlaceVal
            lngVal += col * lngPlaceVal
        }
        val latitudeLo = latVal.toDouble() / LAT_INTEGER_MULTIPLIER
        val longitudeLo = lngVal.toDouble() / LNG_INTEGER_MULTIPLIER
        val latitudeHi = (latVal + latPlaceVal).toDouble() / LAT_INTEGER_MULTIPLIER
        val longitudeHi = (lngVal + lngPlaceVal).toDouble() / LNG_INTEGER_MULTIPLIER
        return CodeArea(
            latitudeLo,
            longitudeLo,
            latitudeHi,
            longitudeHi,
            min(clean.length, MAX_DIGIT_COUNT)
        )
    }

    /**
     * Returns short [OpenLocationCode] from the full Open Location Code created by removing
     * four or six digits, depending on the provided reference point. It removes as many digits as
     * possible.
     *
     * @param referenceLatitude Degrees.
     * @param referenceLongitude Degrees.
     * @return A short code if possible.
     */
    fun shorten(referenceLatitude: Double, referenceLongitude: Double): OpenLocationCode {
        check(isFull) { "shorten() method could only be called on a full code." }
        check(!isPadded) { "shorten() method can not be called on a padded code." }

        val codeArea = decode()
        val range = max(
            abs(referenceLatitude - codeArea.centerLatitude),
            abs(referenceLongitude - codeArea.centerLongitude)
        )
        // We are going to check to see if we can remove three pairs, two pairs or just one pair of
        // digits from the code.
        for (i in 4 downTo 1) {
            // Check if we're close enough to shorten. The range must be less than 1/2
            // the precision to shorten at all, and we want to allow some safety, so
            // use 0.3 instead of 0.5 as a multiplier.
            if (range < computeLatitudePrecision(i * 2) * 0.3) {
                // We're done.
                return OpenLocationCode(code.substring(i * 2))
            }
        }
        throw IllegalArgumentException(
            "Reference location is too far from the Open Location Code center."
        )
    }

    /**
     * Returns an [OpenLocationCode] object representing a full Open Location Code from this
     * (short) Open Location Code, given the reference location.
     *
     * @param referenceLatitude Degrees.
     * @param referenceLongitude Degrees.
     * @return The nearest matching full code.
     */
    fun recover(referenceLatitude: Double, referenceLongitude: Double): OpenLocationCode {
        if (isFull) {
            // Note: each code is either full xor short, no other option.
            return this
        }

        val clippedReferenceLatitude = clipLatitude(referenceLatitude)
        val normalizedReferenceLongitude = normalizeLongitude(referenceLongitude)
        
        val digitsToRecover = SEPARATOR_POSITION - code.indexOf(SEPARATOR)
        // The precision (height and width) of the missing prefix in degrees.
        val prefixPrecision = ENCODING_BASE.toDouble().pow((2 - digitsToRecover / 2).toDouble())

        // Use the reference location to generate the prefix.
        val recoveredPrefix = fromLatLong(clippedReferenceLatitude, normalizedReferenceLongitude)
            .code.substring(0, digitsToRecover)
        // Combine the prefix with the short code and decode it.
        val recovered = OpenLocationCode(recoveredPrefix + code)
        val recoveredCodeArea = recovered.decode()
        // Work out whether the new code area is too far from the reference location. If it is, we
        // move it. It can only be out by a single precision step.
        var recoveredLatitude = recoveredCodeArea.centerLatitude
        var recoveredLongitude = recoveredCodeArea.centerLongitude

        // Move the recovered latitude by one precision up or down if it is too far from the reference,
        // unless doing so would lead to an invalid latitude.
        val latitudeDiff = recoveredLatitude - clippedReferenceLatitude
        if (latitudeDiff > prefixPrecision / 2 && recoveredLatitude - prefixPrecision > -LATITUDE_MAX) {
            recoveredLatitude -= prefixPrecision
        } else if (latitudeDiff < -prefixPrecision / 2 && recoveredLatitude + prefixPrecision < LATITUDE_MAX) {
            recoveredLatitude += prefixPrecision
        }

        // Move the recovered longitude by one precision up or down if it is too far from the
        // reference.
        val longitudeDiff = recoveredCodeArea.centerLongitude - normalizedReferenceLongitude
        if (longitudeDiff > prefixPrecision / 2) {
            recoveredLongitude -= prefixPrecision
        } else if (longitudeDiff < -prefixPrecision / 2) {
            recoveredLongitude += prefixPrecision
        }

        return fromLatLong(recoveredLatitude, recoveredLongitude, recovered.code.length - 1)
    }

    /**
     * Returns whether the bounding box specified by the Open Location Code contains provided point.
     *
     * @param latitude Degrees.
     * @param longitude Degrees.
     * @return True if the coordinates are contained by the code.
     */
    fun contains(latitude: Double, longitude: Double): Boolean {
        val codeArea = decode()
        return (codeArea.southLatitude <= latitude
                && latitude < codeArea.northLatitude
                && codeArea.westLongitude <= longitude
                && longitude < codeArea.eastLongitude)
    }

    override fun equals(other: Any?): Boolean {
        if (this === other) {
            return true
        }
        if (other == null || other !is OpenLocationCode) {
            return false
        }
        return code == other.code
    }

    override fun hashCode(): Int {
        return code.hashCode()
    }

    override fun toString(): String {
        return code
    }

    companion object {

        // Provides a normal precision code, approximately 14x14 meters.
        const val CODE_PRECISION_NORMAL = 10

        // The character set used to encode the values.
        const val CODE_ALPHABET = "23456789CFGHJMPQRVWX"

        // A separator used to break the code into two parts to aid memorability.
        const val SEPARATOR = '+'

        // The character used to pad codes.
        const val PADDING_CHARACTER = '0'

        // The max number of digits to process in a plus code.
        const val MAX_DIGIT_COUNT = 15

        // The number of characters to place before the separator.
        private const val SEPARATOR_POSITION = 8

        // Maximum code length using just lat/lng pair encoding.
        private const val PAIR_CODE_LENGTH = 10

        // Number of digits in the grid coding section.
        private const val GRID_CODE_LENGTH = MAX_DIGIT_COUNT - PAIR_CODE_LENGTH

        // The base to use to convert numbers to/from.
        private const val ENCODING_BASE = CODE_ALPHABET.length

        // The maximum value for latitude in degrees.
        private const val LATITUDE_MAX: Long = 90

        // The maximum value for longitude in degrees.
        private const val LONGITUDE_MAX: Long = 180

        // Number of columns in the grid refinement method.
        private const val GRID_COLUMNS = 4

        // Number of rows in the grid refinement method.
        private const val GRID_ROWS = 5

        // Value to multiple latitude degrees to convert it to an integer with the maximum encoding
        // precision. I.e. ENCODING_BASE**3 * GRID_ROWS**GRID_CODE_LENGTH
        private const val LAT_INTEGER_MULTIPLIER = (8000 * 3125).toLong()

        // Value to multiple longitude degrees to convert it to an integer with the maximum encoding
        // precision. I.e. ENCODING_BASE**3 * GRID_COLUMNS**GRID_CODE_LENGTH
        private const val LNG_INTEGER_MULTIPLIER = (8000 * 1024).toLong()

        // Value of the most significant latitude digit after it has been converted to an integer.
        private const val LAT_MSP_VALUE = LAT_INTEGER_MULTIPLIER * ENCODING_BASE.toLong() * ENCODING_BASE.toLong()

        // Value of the most significant longitude digit after it has been converted to an integer.
        private const val LNG_MSP_VALUE = LNG_INTEGER_MULTIPLIER * ENCODING_BASE.toLong() * ENCODING_BASE.toLong()

        /**
         * Creates Open Location Code.
         *
         * @param latitude The latitude in decimal degrees.
         * @param longitude The longitude in decimal degrees.
         * @param codeLength The desired number of digits in the code.
         * @throws IllegalArgumentException if the code length is not valid.
         */
        @JvmOverloads
        @JvmStatic
        fun fromLatLong(latitude: Double, longitude: Double, codeLength: Int = CODE_PRECISION_NORMAL): OpenLocationCode {
            // Limit the maximum number of digits in the code.
            val fixedCodeLength = min(codeLength, MAX_DIGIT_COUNT)
            // Check that the code length requested is valid.
            require(!(fixedCodeLength < PAIR_CODE_LENGTH && fixedCodeLength % 2 == 1 || fixedCodeLength < 4)) { "Illegal code length $fixedCodeLength" }
            // Ensure that latitude and longitude are valid.

            val clippedLatitude = clipLatitude(latitude).let { clippedLatitude ->
                // Latitude 90 needs to be adjusted to be just less, so the returned code can also be decoded.
                if (clippedLatitude == LATITUDE_MAX.toDouble()) {
                    clippedLatitude - 0.9 * computeLatitudePrecision(fixedCodeLength)
                } else {
                    clippedLatitude
                }
            }
            val normalizedLongitude = normalizeLongitude(longitude)

            // Store the code - we build it in reverse and reorder it afterwards.
            val revCodeBuilder = CharBuffer(MAX_DIGIT_COUNT+1, PADDING_CHARACTER)

            // Compute the code.
            // This approach converts each value to an integer after multiplying it by
            // the final precision. This allows us to use only integer operations, so
            // avoiding any accumulation of floating point representation errors.

            // Multiply values by their precision and convert to positive. Rounding
            // avoids/minimises errors due to floating point precision.
            var latVal = (round((clippedLatitude + LATITUDE_MAX) * LAT_INTEGER_MULTIPLIER.toDouble() * 1e6) / 1e6).toLong()
            var lngVal = (round((normalizedLongitude + LONGITUDE_MAX) * LNG_INTEGER_MULTIPLIER.toDouble() * 1e6) / 1e6).toLong()

            // Compute the grid part of the code if necessary.
            if (fixedCodeLength > PAIR_CODE_LENGTH) {
                for (i in 0 until GRID_CODE_LENGTH) {
                    val latDigit = latVal % GRID_ROWS
                    val lngDigit = lngVal % GRID_COLUMNS
                    val ndx = (latDigit * GRID_COLUMNS + lngDigit).toInt()
                    revCodeBuilder.append(CODE_ALPHABET[ndx])
                    latVal /= GRID_ROWS.toLong()
                    lngVal /= GRID_COLUMNS.toLong()
                }
            } else {
                latVal = (latVal / GRID_ROWS.toDouble().pow(GRID_CODE_LENGTH.toDouble())).toLong()
                lngVal = (lngVal / GRID_COLUMNS.toDouble().pow(GRID_CODE_LENGTH.toDouble())).toLong()
            }
            // Compute the pair section of the code.
            for (i in 0 until PAIR_CODE_LENGTH / 2) {
                revCodeBuilder.append(CODE_ALPHABET[(lngVal % ENCODING_BASE).toInt()])
                revCodeBuilder.append(CODE_ALPHABET[(latVal % ENCODING_BASE).toInt()])
                latVal /= ENCODING_BASE.toLong()
                lngVal /= ENCODING_BASE.toLong()
                // If we are at the separator position, add the separator.
                if (i == 0) {
                    revCodeBuilder.append(SEPARATOR)
                }
            }

            // Reverse the code.
            val codeBuilder = revCodeBuilder.toArray().apply { reverse() }.also { reversedCode ->
                // If we need to pad the code, replace some of the digits.
                if (fixedCodeLength < SEPARATOR_POSITION) {
                    for (i in fixedCodeLength until SEPARATOR_POSITION) {
                        reversedCode[i] = PADDING_CHARACTER
                    }
                }
            }

            return OpenLocationCode(String(codeBuilder).substring(0, max(SEPARATOR_POSITION + 1, fixedCodeLength + 1)))
        }

        /**
         * Encodes latitude/longitude into 10 digit Open Location Code. This method is equivalent to
         * creating the OpenLocationCode object and getting the code from it.
         *
         * @param latitude The latitude in decimal degrees.
         * @param longitude The longitude in decimal degrees.
         * @param codeLength The optional number of digits in the returned code.
         * @return The code.
         */
        @JvmStatic
        @JvmOverloads
        fun encode(latitude: Double, longitude: Double, codeLength: Int = CODE_PRECISION_NORMAL): String {
            return fromLatLong(latitude, longitude, codeLength).code
        }

        /**
         * Decodes code representing Open Location Code into [CodeArea] object encapsulating
         * latitude/longitude bounding box.
         *
         * @param code Open Location Code to be decoded.
         * @return A CodeArea object.
         * @throws IllegalArgumentException if the provided code is not a valid Open Location Code.
         */
        @JvmStatic
        fun decode(code: String): CodeArea {
            return fromString(code).decode()
        }

        /**
         * Decodes code representing Open Location Code into OpenLocationCode objet
         *
         * @param code Open Location Code to be decoded.
         * @return A OpenLocationCode object.
         * @throws IllegalArgumentException if the provided code is not a valid Open Location Code.
         */
        @JvmStatic
        fun fromString(code: String): OpenLocationCode {
            return OpenLocationCode(code)
        }

        /**
         * Returns whether the provided Open Location Code is a full Open Location Code.
         *
         * @param code The code to check.
         * @return True if it is a full code.
         */
        @Suppress("unused")
        @JvmStatic
        fun isFull(code: String): Boolean {
            return OpenLocationCode(code).isFull
        }

        /**
         * Returns whether the provided Open Location Code is a short Open Location Code.
         *
         * @param code The code to check.
         * @return True if it is short.
         */
        @Suppress("unused")
        @JvmStatic
        fun isShort(code: String): Boolean {
            return OpenLocationCode(code).isShort
        }

        /**
         * Returns whether the provided Open Location Code is a padded Open Location Code, meaning that it
         * contains less than 8 valid digits.
         *
         * @param code The code to check.
         * @return True if it is padded.
         */
        @Suppress("unused")
        @JvmStatic
        fun isPadded(code: String): Boolean {
            return OpenLocationCode(code).isPadded
        }

        // Exposed static helper methods.

        /**
         * Returns whether the provided string is a valid Open Location code.
         *
         * @param code The code to check.
         * @return True if it is a valid full or short code.
         */
        @JvmStatic
        fun isValidCode(code: String?): Boolean {
            if (code == null || code.length < 2) {
                return false
            }
            val normalizedCode = code.toUpperCase()

            // There must be exactly one separator.
            val separatorPosition = normalizedCode.indexOf(SEPARATOR)
            if (separatorPosition == -1) {
                return false
            }
            if (separatorPosition != normalizedCode.lastIndexOf(SEPARATOR)) {
                return false
            }
            // There must be an even number of at most 8 characters before the separator.
            if (separatorPosition % 2 != 0 || separatorPosition > SEPARATOR_POSITION) {
                return false
            }

            // Check first two characters: only some values from the alphabet are permitted.
            if (separatorPosition == SEPARATOR_POSITION) {
                // First latitude character can only have first 9 values.
                if (CODE_ALPHABET.indexOf(normalizedCode[0]) > 8) {
                    return false
                }

                // First longitude character can only have first 18 values.
                if (CODE_ALPHABET.indexOf(normalizedCode[1]) > 17) {
                    return false
                }
            }

            // Check the characters before the separator.
            var paddingStarted = false
            for (i in 0 until separatorPosition) {
                if (CODE_ALPHABET.indexOf(normalizedCode[i]) == -1 && normalizedCode[i] != PADDING_CHARACTER) {
                    // Invalid character.
                    return false
                }
                if (paddingStarted) {
                    // Once padding starts, there must not be anything but padding.
                    if (normalizedCode[i] != PADDING_CHARACTER) {
                        return false
                    }
                } else if (normalizedCode[i] == PADDING_CHARACTER) {
                    paddingStarted = true
                    // Short codes cannot have padding
                    if (separatorPosition < SEPARATOR_POSITION) {
                        return false
                    }
                    // Padding can start on even character: 2, 4 or 6.
                    if (i != 2 && i != 4 && i != 6) {
                        return false
                    }
                }
            }

            // Check the characters after the separator.
            if (normalizedCode.length > separatorPosition + 1) {
                if (paddingStarted) {
                    return false
                }
                // Only one character after separator is forbidden.
                if (normalizedCode.length == separatorPosition + 2) {
                    return false
                }
                for (i in separatorPosition + 1 until normalizedCode.length) {
                    if (CODE_ALPHABET.indexOf(normalizedCode[i]) == -1) {
                        return false
                    }
                }
            }

            return true
        }

        /**
         * Returns if the code is a valid full Open Location Code.
         *
         * @param code The code to check.
         * @return True if it is a valid full code.
         */
        @JvmStatic
        fun isFullCode(code: String): Boolean {
            return try {
                OpenLocationCode(code).isFull
            } catch (e: IllegalArgumentException) {
                false
            }

        }

        /**
         * Returns if the code is a valid short Open Location Code.
         *
         * @param code The code to check.
         * @return True if it is a valid short code.
         */
        @JvmStatic
        fun isShortCode(code: String): Boolean {
            return try {
                OpenLocationCode(code).isShort
            } catch (e: IllegalArgumentException) {
                false
            }

        }

        // Private static methods.

        private fun clipLatitude(latitude: Double): Double {
            return min(max(latitude, (-LATITUDE_MAX).toDouble()), LATITUDE_MAX.toDouble())
        }

        private fun normalizeLongitude(longitude: Double): Double {
            var normalizingLongitude = longitude
            while (normalizingLongitude < -LONGITUDE_MAX) {
                normalizingLongitude += LONGITUDE_MAX * 2
            }
            while (normalizingLongitude >= LONGITUDE_MAX) {
                normalizingLongitude -= LONGITUDE_MAX * 2
            }
            return normalizingLongitude
        }

        /**
         * Compute the latitude precision value for a given code length. Lengths <= 10 have the same
         * precision for latitude and longitude, but lengths > 10 have different precisions due to the
         * grid method having fewer columns than rows. Copied from the JS implementation.
         */
        private fun computeLatitudePrecision(codeLength: Int): Double {
            return if (codeLength <= CODE_PRECISION_NORMAL) {
                ENCODING_BASE.toDouble().pow((codeLength / -2 + 2).toDouble())
            } else {
                ENCODING_BASE.toDouble().pow(-3.0) / GRID_ROWS.toDouble().pow(
                    (codeLength - PAIR_CODE_LENGTH).toDouble()
                )
            }
        }
    }
}
