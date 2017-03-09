using System.Linq;

namespace Google.OpenLocationCode
{
    internal static class Validator
    {
        /// <summary>
        /// Gets whether the provided code string is a valid Open Location Code
        /// </summary>
        /// <param name="code">Open Location Code value to validate</param>
        /// <returns>Returns true if the provided code string is a valid Open Location Code, false otherwise</returns>
        public static bool Validate( string code )
        {
            if ( string.IsNullOrWhiteSpace( code ) || code.Length < 2 )
            {
                return ( false );
            }

            // There must be exactly one separator
            if ( code.Count( x => x == Constants.Separator ) != 1 )
            {
                return ( false );
            }

            int? separatorIndex = GetSeparatorIndex( code );

            if ( !separatorIndex.HasValue )
            {
                // separator validation failed
                return ( false );
            }

            // Check the characters before the separator
            bool paddingStarted = false;
            if ( !IsPrefixValid( separatorIndex.Value, code, ref paddingStarted ) )
            {
                return ( false );
            }

            // Check the characters after the separator
            if ( !IsSuffixValid( separatorIndex.Value, code, paddingStarted ) )
            {
                return ( false );
            }

            return ( true );
        }

        private static int? GetSeparatorIndex( string code )
        {
            int separatorIndex = code.IndexOf( Constants.Separator );

            if ( separatorIndex % 2 != 0 )
            {
                return ( null );
            }

            // Check first two characters: only some values from the alphabet are permitted
            if ( separatorIndex == 8 )
            {
                // First latitude character can only have first 9 values
                int? index = Constants.AlphabetIndex.GetNullableValue( code[ 0 ] );
                if ( !index.HasValue || ( index > 8 ) )
                {
                    return ( null );
                }

                // First longitude character can only have first 18 values
                index = Constants.AlphabetIndex.GetNullableValue( code[ 1 ] );
                if ( !index.HasValue || ( index > 17 ) )
                {
                    return ( null );
                }
            }

            return ( separatorIndex );
        }

        private static bool IsPrefixValid( int separatorIndex, string code, ref bool paddingStarted )
        {
            for ( int idx = 0; idx < separatorIndex; idx++ )
            {
                if ( paddingStarted )
                {
                    // Once padding starts, there must not be anything but padding.
                    if ( code[ idx ] != Constants.PaddingSuffix )
                    {
                        return ( false );
                    }

                    continue;
                }

                if ( Constants.AlphabetIndex.ContainsKey( code[ idx ] ) )
                {
                    continue;
                }

                if ( Constants.PaddingSuffix == code[ idx ] )
                {
                    paddingStarted = true;

                    // Padding can start on even character: 2, 4 or 6.
                    if ( ( idx != 2 ) && ( idx != 4 ) && ( idx != 6 ) )
                    {
                        return ( false );
                    }

                    continue;
                }

                // Illegal character
                return ( false );
            }

            return ( true );
        }

        private static bool IsSuffixValid( int separatorIndex, string code, bool paddingStarted )
        {
            if ( code.Length > separatorIndex + 1 )
            {
                if ( paddingStarted )
                {
                    return ( false );
                }

                // Only one character after separator is forbidden.
                if ( code.Length == separatorIndex + 2 )
                {
                    return ( false );
                }

                for ( int i = separatorIndex + 1; i < code.Length; i++ )
                {
                    if ( !Constants.AlphabetIndex.ContainsKey( code[ i ] ) )
                    {
                        return ( false );
                    }
                }
            }

            return ( true );
        }
    }
}
