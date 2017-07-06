using System.Globalization;

namespace OpenLocationCode
{
    public sealed class Bounds
    {
        private readonly decimal southLatitude;
        private readonly decimal westLongitude;
        private readonly decimal northLatitude;
        private readonly decimal eastLongitude;

        public Bounds( decimal southLatitude, decimal westLongitude, decimal northLatitude, decimal eastLongitude )
        {
            this.southLatitude = southLatitude;
            this.westLongitude = westLongitude;
            this.northLatitude = northLatitude;
            this.eastLongitude = eastLongitude;
        }

        public double SouthLatitude
        {
            get
            {
                return ( (double)southLatitude );
            }
        }

        public double WestLongitude
        {
            get
            {
                return ( (double)westLongitude );
            }
        }

        public double NorthLatitude
        {
            get
            {
                return ( (double)northLatitude );
            }
        }

        public double EastLongitude
        {
            get
            {
                return ( (double)eastLongitude );
            }
        }

        public double CenterLatitude
        {
            get
            {
                return ( (double)( southLatitude + northLatitude ) / 2.0 );
            }
        }

        public double CenterLongitude
        {
            get
            {
                return ( (double)( westLongitude + eastLongitude ) / 2.0 );
            }
        }

        public override string ToString()
        {
            return ( string.Format( CultureInfo.InvariantCulture, "[{0:F5},{1:F5}],[{2:F5},{3:F5}]"
                , northLatitude
                , westLongitude
                , southLatitude
                , eastLongitude ) );
        }
    }
}
