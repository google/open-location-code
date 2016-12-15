using System;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using System.Collections.Generic;
using System.Linq;
using Google.OpenLocationCode;

namespace Fonix.Tests
{
    [TestClass]
    public class EncodingTests
    {
        [TestMethod]
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

                Assert.AreEqual( item.Code, encoded
                    , string.Format( "Latitude and longitude [{0:F5},{1:F5}] were wrongly encoded."
                    , item.Latitude
                    , item.Longitude ) );
            }
        }

        [TestMethod]
        public void TestDecoding()
        {
            double precision = 0.000125;

            var data = LoadTestData();

            foreach ( var item in data )
            {
                var bounds = new OpenLocationCode( item.Code ).GetBounds();

                Assert.AreEqual( item.DecodedLatitudeLo, bounds.SouthLatitude, precision
                    , string.Format( "Wrong low latitude for code '{0}'.", item.Code ) );

                Assert.AreEqual( item.DecodedLatitudeHi, bounds.NorthLatitude, precision
                    , string.Format( "Wrong high latitude for code '{0}'.", item.Code ) );

                Assert.AreEqual( item.DecodedLongitudeLo, bounds.WestLongitude, precision
                    , string.Format( "Wrong low longitude for code '{0}'.", item.Code ) );

                Assert.AreEqual( item.DecodedLongitudeHi, bounds.EastLongitude, precision
                    , string.Format( "Wrong high longitude for code '{0}'.", item.Code ) );
            }
        }

        [TestMethod]
        public void TestClipping()
        {
            Assert.AreEqual( OpenLocationCode.Encode( -90, 5 ), OpenLocationCode.Encode( -91, 5 )
                , "Clipping of negative latitude doesn't work." );

            Assert.AreEqual( OpenLocationCode.Encode( 90, 5 ), OpenLocationCode.Encode( 91, 5 )
                , "Clipping of positive latitude doesn't work." );

            Assert.AreEqual( OpenLocationCode.Encode( -5, 175 ), OpenLocationCode.Encode( -5, -185 )
                , "Clipping of very long negative longitude doesn't work." );

            Assert.AreEqual( OpenLocationCode.Encode( -5, 175 ), OpenLocationCode.Encode( -5, -905 )
                , "Clipping of very long negative longitude doesn't work." );

            Assert.AreEqual( OpenLocationCode.Encode( -5, -175 ), OpenLocationCode.Encode( -5, 905 )
                , "Clipping of very long positive longitude doesn't work." );

        }

        [TestMethod]
        public void TestContains()
        {
            var data = LoadTestData();

            foreach ( var item in data )
            {
                var code = new OpenLocationCode( item.Code );
                var bounds = code.GetBounds();

                Assert.IsTrue( code.Contains( bounds.CenterLatitude, bounds.CenterLongitude )
                    , string.Format( "Containment relation is broken for the decoded middle point of code '{0}'.", item.Code ) );

                Assert.IsTrue( code.Contains( bounds.SouthLatitude, bounds.WestLongitude )
                    , string.Format( "Containment relation is broken for the decoded bottom left corner of code '{0}'.", item.Code ) );

                Assert.IsFalse( code.Contains( bounds.NorthLatitude, bounds.EastLongitude )
                    , string.Format( "Containment relation is broken for the decoded top right corner of code '{0}'.", item.Code ) );

                Assert.IsFalse( code.Contains( bounds.SouthLatitude, bounds.EastLongitude )
                    , string.Format( "Containment relation is broken for the decoded bottom right corner of code '{0}'.", item.Code ) );

                Assert.IsFalse( code.Contains( bounds.NorthLatitude, bounds.WestLongitude )
                    , string.Format( "Containment relation is broken for the decoded top left corner of code '{0}'.", item.Code ) );
            }
        }

        private IEnumerable<TestData> LoadTestData()
        {
            var lines = System.IO.File.ReadAllLines( @"..\..\..\..\..\test_data\encodingTests.csv" )
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
