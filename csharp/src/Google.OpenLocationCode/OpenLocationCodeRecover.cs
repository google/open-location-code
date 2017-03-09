using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace Google.OpenLocationCode
{
    public static class OpenLocationCodeRecover
    {
        public static OpenLocationCode Recover( this OpenLocationCode code, double latitude, double longitude )
        {
            if ( code.IsFull )
            {
                return ( code );
            }

            latitude = Builder.ClipLatitude( latitude );
            longitude = Builder.NormalizeLongitude( longitude );

            int digitsToRecover = 8 - code.Code.IndexOf( Constants.Separator );
            double paddedArea = Math.Pow( 20, 2 - ( digitsToRecover / 2 ) );

            // use reference location to pad the supplied code
            string prefix = OpenLocationCode.Encode( latitude, longitude )
                .Substring( 0, digitsToRecover );

            var recoveredCode = new OpenLocationCode( prefix + code.Code );
            var recoveredCodeBounds = recoveredCode.Decode();

            double recoveredLatitude = recoveredCodeBounds.CenterLatitude;
            double recoveredLongitude = recoveredCodeBounds.CenterLongitude;

            // adjust latitude resolution
            double latitudeDiff = recoveredLatitude - latitude;

            if ( latitudeDiff > ( paddedArea / 2 ) )
            {
                recoveredLatitude -= paddedArea;
            }
            else if ( latitudeDiff < ( -paddedArea / 2 ) )
            {
                recoveredLatitude += paddedArea;
            }

            // adjust longitude resolution
            double longitudeDiff = recoveredLongitude - longitude;

            if ( longitudeDiff > ( paddedArea / 2 ) )
            {
                recoveredLongitude -= paddedArea;
            }
            else if ( longitudeDiff < ( -paddedArea / 2 ) )
            {
                recoveredLongitude += paddedArea;
            }

            return ( new OpenLocationCode( recoveredLatitude, recoveredLongitude, recoveredCode.Code.Length - 1 ) );
        }
    }
}
