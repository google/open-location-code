using System;
using System.Text.RegularExpressions;

namespace OpenLocationCode
{
    public static class OpenLocationCodeShorten
    {
        /// <summary>
        /// Shortens the full code by removing four or six digits, depending on the provided reference point
        /// </summary>
        /// <param name="latitude">Reference location latitude</param>
        /// <param name="longitude">Reference location longitude</param>
        /// <returns>Returns a new Open Location Code with less digits</returns>
        public static OpenLocationCode Shorten( this OpenLocationCode code, double latitude, double longitude )
        {
            if ( !code.IsFull )
            {
                throw new InvalidOperationException( "Can only shorten a full Open Location Code." );
            }

            if ( code.IsPadded )
            {
                throw new InvalidOperationException( "Can only shorten an Open Location Code that isn't padded." );
            }

            Bounds bounds = code.Decode();

            double latitudeDiff = Math.Abs( latitude - bounds.CenterLatitude );
            double longitudeDiff = Math.Abs( longitude - bounds.CenterLongitude );

            if ( latitudeDiff < Constants.LatitudePrecision8Digits && longitudeDiff < Constants.LatitudePrecision8Digits )
            {
                return ( new OpenLocationCode( code.Code.Substring( 8 ) ) );
            }
            else if ( latitudeDiff < Constants.LatitudePrecision6Digits && longitudeDiff < Constants.LatitudePrecision6Digits )
            {
                return ( new OpenLocationCode( code.Code.Substring( 6 ) ) );
            }
            else if ( latitudeDiff < Constants.LatitudePrecision4Digits && longitudeDiff < Constants.LatitudePrecision4Digits )
            {
                return ( new OpenLocationCode( code.Code.Substring( 4 ) ) );
            }

            throw new ArgumentException( "Location is too far from the Open Location Code center." );
        }
    }
}
