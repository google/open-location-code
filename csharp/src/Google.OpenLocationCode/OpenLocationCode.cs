﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace Google.OpenLocationCode
{
    public sealed class OpenLocationCode : IEquatable<OpenLocationCode>
    {
        public OpenLocationCode( string code )
        {
            if ( !Validator.Validate( code ) )
            {
                throw new ArgumentException( string.Format( "'{0}' is not a valid Open Location code.", code ) );
            }

            Code = code.ToUpper();
        }

        /// <summary>
        /// Creates an Open Location Code from the provided latitude, longitude and desired code length
        /// </summary>
        public OpenLocationCode( double latitude, double longitude, int codeLength )
        {
            Code = Builder.New( latitude, longitude, codeLength );
        }

        /// <summary>
        /// Creates Open Location Code with code length 10 from the provided latitude, longitude
        /// </summary>
        public OpenLocationCode( double latitude, double longitude )
        {
            Code = Builder.New( latitude, longitude, 10 );
        }

        /// <summary>
        /// Gets the code value as string. Same as invoking ToString() method.
        /// </summary>
        public string Code { get; private set; }

        /// <summary>
        /// Gets whether this is a full Open Location Code
        /// </summary>
        public bool IsFull
        {
            get
            {
                return ( Code.IndexOf( Constants.Separator ) == Constants.SeparatorIndex );
            }
        }

        /// <summary>
        /// Gets whether this is a padded Open Location Code, meaning that it contains less than 8 valid digits
        /// </summary>
        public bool IsPadded
        {
            get
            {
                return ( Code.Contains( Constants.PaddingSuffix ) );
            }
        }

        /// <summary>
        /// Creates an Open Location Code from the provided latitude, longitude and desired code length and returns as string
        /// </summary>
        /// <returns>Returns Open Location Code as string</returns>
        public static string Encode( double latitude, double longitude, int codeLength )
        {
            var code = new OpenLocationCode( latitude, longitude, codeLength );

            return ( code.Code );
        }

        /// <summary>
        /// Creates Open Location Code with code length 10 from the provided latitude, longitude and returns as string
        /// </summary>
        /// <returns>Returns Open Location Code as string</returns>
        public static string Encode( double latitude, double longitude )
        {
            var code = new OpenLocationCode( latitude, longitude );

            return ( code.Code );
        }

        public static Bounds Decode( string code )
        {
            var locationCode = new OpenLocationCode( code );

            return ( locationCode.Decode() );
        }

        public static OpenLocationCode Shorten( string code, double latitude, double longitude )
        {
            var locationCode = new OpenLocationCode( code );

            return ( locationCode.Shorten( latitude, longitude ) );
        }

        public static OpenLocationCode Recover( string code, double latitude, double longitude )
        {
            var locationCode = new OpenLocationCode( code );

            return ( locationCode.Recover( latitude, longitude ) );
        }

        /// <summary>
        /// Gets whether a given latitude/longitude is within the Open Location Code area
        /// </summary>
        /// <returns>Returnes true if the latitude/longitude is within the Open Location Code area, false otherwise</returns>
        public bool Contains( double latitude, double longitude )
        {
            Bounds bounds = this.Decode();

            bool contains = ( bounds.SouthLatitude <= latitude ) && ( latitude < bounds.NorthLatitude )
                && ( bounds.WestLongitude <= longitude ) && ( longitude < bounds.EastLongitude );

            return ( contains );
        }

        public bool Equals( OpenLocationCode other )
        {
            if ( other == null )
            {
                return ( false );
            }

            return ( Code.Equals( other.Code ) );
        }

        /// <summary>
        /// Returns a string with the code value
        /// </summary>
        /// <returns></returns>
        public override string ToString()
        {
            return ( Code );
        }

        public override int GetHashCode()
        {
            return ( Code?.GetHashCode() ?? 0 );
        }
    }
}
