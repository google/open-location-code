using System;
using System.Text.RegularExpressions;

namespace Google.OpenLocationCode
{
    public static class OpenLocationCodeExtensions
    {
        /// <summary>
        /// Decodes code into object encapsulating latitude/longitude bounding box
        /// </summary>
        /// <returns>Returns the area boundaries for the provided code</returns>
        public static OpenLocationCodeBounds GetBounds( this OpenLocationCode code )
        {
            if ( !code.IsFull )
            {
                throw new InvalidOperationException( string.Format( "'{0}' is not a full Open Location Code. Only full codes can be decoded.", code.Code ) );
            }

            string decoded = Regex.Replace( code.Code, "[0+]", "" );

            // Decode the lat/lng pair component.
            decimal southLatitude = 0;
            decimal westLongitude = 0;

            int digit = 0;
            double latitudeResolution = 400;
            double longitudeResolution = 400;

            // Decode pair
            while ( digit < decoded.Length )
            {
                if ( digit < 10 )
                {
                    latitudeResolution /= 20.0;
                    longitudeResolution /= 20.0;
                    southLatitude += new decimal( latitudeResolution * Constants.AlphabetIndex[ decoded[ digit ] ] );
                    westLongitude += new decimal( longitudeResolution * Constants.AlphabetIndex[ decoded[ digit + 1 ] ] );
                    digit += 2;
                }
                else
                {
                    latitudeResolution /= 5;
                    longitudeResolution /= 4;
                    southLatitude += new decimal( latitudeResolution * ( Constants.AlphabetIndex[ decoded[ digit ] ] / 4.0 ) );
                    westLongitude += new decimal( longitudeResolution * ( Constants.AlphabetIndex[ decoded[ digit ] ] % 4.0 ) );
                    digit += 1;
                }
            }

            var codeArea = new OpenLocationCodeBounds(
                  southLatitude - 90
                , westLongitude - 180
                , ( southLatitude - 90 ) + new decimal( latitudeResolution )
                , ( westLongitude - 180 ) + new decimal( longitudeResolution ) );

            return ( codeArea );
        }
    }
}
