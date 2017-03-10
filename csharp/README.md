# Open Location Code

This is a C# implementation of Google Open Location Code (Plus+Codes).

## Building

The whole project is built using .NET Core to support both NET Framework and NET Standard. To build the project, just use dotnet CLI.
There's also a solution file that can be used to open using Visual Studio.

```
dotnet build
```

## Tests

There's a test project under the test folder. These tests can be executed by using dotnet CLI. You can also use the Visual Studio solution.
Not all tests are in the project, but more will be added soon.

```
dotnet test
```

## Usage

```csharp

// encoding a latitude and longitude into an Open Location Code
string code = OpenLocationCode.Encode( 51.506187,-0.116438 );
// output:  9C3XGV4M+FC

// decoding an Open Location Code into an area
OpenLocationCode olc = new OpenLocationCode( code );
var bounds = olc.Decode();

// check if a code is valid
var badc = new OpenLocationCode( "SDJROFRH" );
// throws ArgumentException

// shortening a code
var shortCode = olc.Shorten();

// recovering a code
var recoveredCode = shortCode.Recover( 51.506187,-0.116438 );

// static methods
var shortCode2 = OpenLocationCode.Shorten( "9C3XGV4M+FC", 51.506187,-0.116438 );
var bounds2 = OpenLocationCode.Decode( "9C3XGV4M+FC" );
var recoveredCode2 = OpenLocationCode.Recover( "9C3XGV4M+FC", 51.506187,-0.116438 );
```
