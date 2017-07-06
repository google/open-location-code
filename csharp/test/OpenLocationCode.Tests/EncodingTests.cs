using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Xunit;

namespace Google.OpenLocationCode.Tests
{
    public class EncodingTests
    {
        [Fact]
        public void TestEncoding()
        {
            var data = LoadTestData();

            foreach ( var item in data )
            {
                int codeLength = item.Code.Length - 1;

                if ( item.Code.IndexOf( '0' ) > -1 )
                {
                    codeLength = item.Code.IndexOf( '0' );
                }

                var encoded = OpenLocationCode.Encode( item.Latitude, item.Longitude, codeLength )
                    .ToString();

                Assert.Equal( item.Code, encoded );
            }
        }

        [Fact]
        public void TestDecoding()
        {
            int precision = 2;

            var data = LoadTestData();

            foreach ( var item in data )
            {
                var bounds = new OpenLocationCode( item.Code ).Decode();

                Assert.Equal( item.DecodedLatitudeLo, bounds.SouthLatitude, precision );
                Assert.Equal( item.DecodedLatitudeHi, bounds.NorthLatitude, precision );
                Assert.Equal( item.DecodedLongitudeLo, bounds.WestLongitude, precision );
                Assert.Equal( item.DecodedLongitudeHi, bounds.EastLongitude, precision );
            }
        }

        [Fact]
        public void TestClipping()
        {
            Assert.Equal( OpenLocationCode.Encode( -90, 5 ), OpenLocationCode.Encode( -91, 5 ) );
            Assert.Equal( OpenLocationCode.Encode( 90, 5 ), OpenLocationCode.Encode( 91, 5 ) );
            Assert.Equal( OpenLocationCode.Encode( -5, 175 ), OpenLocationCode.Encode( -5, -185 ) );
            Assert.Equal( OpenLocationCode.Encode( -5, 175 ), OpenLocationCode.Encode( -5, -905 ) );
            Assert.Equal( OpenLocationCode.Encode( -5, -175 ), OpenLocationCode.Encode( -5, 905 ) );
        }

        [Fact]
        public void TestContains()
        {
            var data = LoadTestData();

            foreach ( var item in data )
            {
                var code = new OpenLocationCode( item.Code );
                var bounds = code.Decode();

                Assert.True( code.Contains( bounds.CenterLatitude, bounds.CenterLongitude ) );
                Assert.True( code.Contains( bounds.SouthLatitude, bounds.WestLongitude ) );
                Assert.False( code.Contains( bounds.NorthLatitude, bounds.EastLongitude ) );
                Assert.False( code.Contains( bounds.SouthLatitude, bounds.EastLongitude ) );
                Assert.False( code.Contains( bounds.NorthLatitude, bounds.WestLongitude ) );
            }
        }

        private IEnumerable<TestData> LoadTestData()
        {
            var lines = System.IO.File.ReadAllLines( @"../../../../../../../test_data/encodingTests.csv" )
                .Where( x => !x.StartsWith( "#" ) )
                .ToArray();

            List<TestData> data = new List<TestData>( lines.Length );

            foreach ( string line in lines )
            {
                data.Add( new TestData( line ) );
            }

            return ( data );
        }

        private class TestData
        {
            public TestData( string line )
            {
                var parts = line.Split( ',' );

                if ( parts.Length != 7 )
                {
                    throw new ArgumentException( "Test input line format is not correct!" );
                }

                Code = parts[ 0 ];
                Latitude = double.Parse( parts[ 1 ] );
                Longitude = double.Parse( parts[ 2 ] );
                DecodedLatitudeLo = double.Parse( parts[ 3 ] );
                DecodedLongitudeLo = double.Parse( parts[ 4 ] );
                DecodedLatitudeHi = double.Parse( parts[ 5 ] );
                DecodedLongitudeHi = double.Parse( parts[ 6 ] );
            }

            public string Code { get; private set; }
            public double Latitude { get; private set; }
            public double Longitude { get; private set; }
            public double DecodedLatitudeLo { get; private set; }
            public double DecodedLatitudeHi { get; private set; }
            public double DecodedLongitudeLo { get; private set; }
            public double DecodedLongitudeHi { get; private set; }
        }
    }
}
