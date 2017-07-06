using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Linq;
using System.Threading.Tasks;

namespace OpenLocationCode
{
    internal static class Constants
    {
        public const char Separator = '+';
        public const int SeparatorIndex = 0x08;
        public const char PaddingSuffix = '0';

        public static readonly char[] Alphabet = { '2', '3', '4', '5', '6', '7', '8', '9', 'C', 'F', 'G', 'H', 'J', 'M', 'P', 'Q', 'R', 'V', 'W', 'X' };
        public static readonly ReadOnlyDictionary<char, int> AlphabetIndex = new ReadOnlyDictionary<char, int>( new Dictionary<char, int>
        {
            { '2', 0 }, { '3', 1 }, { '4', 2 }, { '5', 3 }, { '6', 4 }, { '7', 5 }, { '8', 6 }, { '9', 7 },
            { 'C', 8 }, { 'c', 8 },
            { 'F', 9 }, { 'f', 9 },
            { 'G', 10 }, { 'g', 10 },
            { 'H', 11 }, { 'h', 11 },
            { 'J', 12 }, { 'j', 12 },
            { 'M', 13 }, { 'm', 13 },
            { 'P', 14 }, { 'p', 14 },
            { 'Q', 15 }, { 'q', 15 },
            { 'R', 16 }, { 'r', 16 },
            { 'V', 17 }, { 'v', 17 },
            { 'W', 18 }, { 'w', 18 },
            { 'X', 19 }, { 'x', 19 }
        } );

        public const double LatitudePrecision8Digits = 0.000625;
        public const double LatitudePrecision6Digits = 0.0125;
        public const double LatitudePrecision4Digits = 0.25;
    }
}
