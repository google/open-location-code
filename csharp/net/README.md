# Open Location Code

This is a C# implementation of Google Open Location Code (Plus+Codes).

## Usage

```csharp

// encoding a latitude and longitude into an Open Location Code
string code = OpenLocationCode.Encode( 51.506187,-0.116438 );
// output:  9C3XGV4M+FC

// decoding an Open Location Code into an area
OpenLocationCode olc = new OpenLocationCode( code );
var bounds = olc.GetBounds();

// check if a code is valid
var badc = new OpenLocationCode( "SDJROFRH" );
// throws ArgumentException
```
