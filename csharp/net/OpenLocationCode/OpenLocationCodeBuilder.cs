using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Google.OpenLocationCode
{
    internal static class OpenLocationCodeBuilder
    {
        public static string New( double latitude, double longitude, int codeLength )
        {
            if ( codeLength < 4 || ( codeLength < 10 & codeLength % 2 == 1 ) )
            {
                throw new ArgumentException( string.Format( "Code length {0} is invalid.", codeLength ) );
            }

            latitude = ClipLatitude( latitude );
            longitude = NormalizeLongitude( longitude );

            // Latitude 90 needs to be adjusted to be just less, so the returned code can also be decoded.
            if ( latitude == 90.0 )
            {
                latitude = latitude - 0.9 * ComputeLatitudePrecision( codeLength );
            }

            StringBuilder codeBuilder = new StringBuilder();

            // Ensure the latitude and longitude are within [0, 180] and [0, 360) respectively.
            /* Note: double type can't be used because of the rounding arithmetic due to floating point
             * implementation. Eg. "8.95 - 8" can give result 0.9499999999999 instead of 0.95 which
             * incorrectly classify the points on the border of a cell.
             */
            decimal remainingLongitude = new decimal( longitude + 180.0 );
            decimal remainingLatitude = new decimal( latitude + 90.0 );

            int generatedDigits = 0;

            while ( generatedDigits < codeLength )
            {
                // Always the integer part of the remaining latitude/longitude will be used for the following digit
                if ( generatedDigits == 0 )
                {
                    // First step World division: Map <0..400) to <0..20) for both latitude and longitude.
                    remainingLatitude = remainingLatitude / 20;
                    remainingLongitude = remainingLongitude / 20;
                }
                else if ( generatedDigits < 10 )
                {
                    remainingLatitude = remainingLatitude * 20;
                    remainingLongitude = remainingLongitude * 20;
                }
                else
                {
                    remainingLatitude = remainingLatitude * 5;
                    remainingLongitude = remainingLongitude * 4;
                }

                int latitudeDigit = (int)remainingLatitude;
                int longitudeDigit = (int)remainingLongitude;

                if ( generatedDigits < 10 )
                {
                    codeBuilder.Append( Constants.Alphabet[ latitudeDigit ] );
                    codeBuilder.Append( Constants.Alphabet[ longitudeDigit ] );

                    generatedDigits += 2;
                }
                else
                {
                    codeBuilder.Append( Constants.Alphabet[ 4 * latitudeDigit + longitudeDigit ] );

                    generatedDigits += 1;
                }

                remainingLatitude = remainingLatitude - new decimal( latitudeDigit );
                remainingLongitude = remainingLongitude - new decimal( longitudeDigit );

                if ( generatedDigits == Constants.SeparatorIndex )
                {
                    codeBuilder.Append( Constants.Separator );
                }
            }

            if ( generatedDigits < Constants.SeparatorIndex )
            {
                for ( ; generatedDigits < Constants.SeparatorIndex; generatedDigits++ )
                {
                    codeBuilder.Append( Constants.PaddingSuffix );
                }

                codeBuilder.Append( Constants.Separator );
            }

            return ( codeBuilder.ToString() );
        }

        private static double ComputeLatitudePrecision( int codeLength )
        {
            if ( codeLength <= 10 )
            {
                return ( Math.Pow( 20.0, Math.Floor( codeLength / -2.0 + 2.0 ) ) );
            }

            return Math.Pow( 20.0, -3.0 ) / Math.Pow( 5.0, codeLength - 10.0 );
        }

        private static double ClipLatitude( double latitude )
        {
            return ( Math.Min( Math.Max( latitude, -90.0 ), 90.0 ) );
        }

        private static double NormalizeLongitude( double longitude )
        {
            if ( longitude < -180.0 )
            {
                longitude = ( longitude % 360.0 ) + 360.0;
            }

            if ( longitude >= 180.0 )
            {
                longitude = ( longitude % 360.0 ) - 360.0;
            }

            return ( longitude );
        }
    }
}
