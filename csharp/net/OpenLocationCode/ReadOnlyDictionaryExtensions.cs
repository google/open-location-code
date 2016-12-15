using System;
using System.Collections.ObjectModel;

namespace Google.OpenLocationCode
{
    internal static class ReadOnlyDictionaryExtensions
    {
        public static TValue? GetNullableValue<TKey, TValue>( this ReadOnlyDictionary<TKey, TValue> source, TKey key ) where TValue : struct, IComparable
        {
            if ( !source.ContainsKey( key ) )
            {
                return null;
            }

            return source[ key ];
        }
    }
}
