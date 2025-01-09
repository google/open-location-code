# Supporting Plus Codes technology in apps and sites

This page gives guidelines for how to support Plus Codes in a website or mapping application.
These guidelines should make it clear that adding support for OLC is not onerous, but actually quite easy.

> Note that with the availability of the [https://plus.codes website API](plus.codes_Website_API.md), these instructions really only apply to apps that require offline support.
If your app or site can rely on a network connection, integrating with the API will give a better solution.

# Supporting Plus Codes for search

To support Plus Codes for searching, there are three different cases:

* global codes, such as "796RWF8Q+WF"
* local codes, such as "WF8Q+WF"
* local codes with a locality, such as "WF8Q+WF Praia, Cabo Verde"

The assumption is that this is being done by a mapping application, that allows people to enter queries and then highlights that location on a map or uses it for directions.

## Supporting global codes

Global codes can be recognised and extracted from a query using a regular expression:

```
/(^|\s)([23456789C][23456789CFGHJMPQRV][23456789CFGHJMPQRVWX]{6}\+[23456789CFGHJMPQRVWX]{2,7})(\s|$)/?i
```

This will extract (in capturing group **2**) a global code at the start or end of a string, or enclosed with spaces.
It will not match a global code embedded in a string such as "777796RWF8Q+WFFFFFFF".

If a location query includes a global code, the rest of the query can be ignored, since the global code gives the latitude and longitude.

To support a global code, once you have the user query, match it against the above regex, and if you have a match use the `decode()` method to get the coordinates, and use the center latitude and longitude.

## Supporting local codes

A variant of the global code regex can be used to check whether a location query includes a local code:

```
/(^|\s)([23456789CFGHJMPQRVWX]{4,6}\+[23456789CFGHJMPQRVWX]{2,3})(\s|$)/?i
```

If the query matches, *and the user has not entered any other text*, then another location must be used to recover the original code.
If you are displaying a map to the user, then use the current map center, pass it to the `recoverNearest()` method to get a global code, and then decode it as above.

If there is no map, you can use the device location.
If you have no map and cannot determine the device location, a local code is not sufficient and you should display a message back to the user asking them to provide a town or city name or the full global code.

## Supporting local codes with localities

If the user input includes a local code with some other text, then extract the local code and send the remaining text to your geocoding service (Nominatim, Google, etc).
Use the location returned by your geocoding service as the reference location in the `recoverNearest()` method to get a global code, decode that and you have the location.

## Displaying the result

If the user specified a Plus Code in their query, the result should match.
That is, it is easier to understand if they enter a Plus Code to get a Plus Code displayed as the result.
Searching for a Plus Code and displaying the result back to the user as "14°55'02.3"N 23°30'40.7"W" is confusing, unhelpful and should be avoided.

# Computing Plus Codes for places

Superficially computing Plus Codes for places is trivial.
All that is needed is to call the `encode()` method on the coordinates, and then to display the code.

The problem is that this only displays the global code, not the more convenient and easy to remember local code.
But to display the local code, you need to do two things:

* Compute the locality name
* Ensure that the locality is located near enough

## Computing a locality name

To display a local code (e.g., WF8Q+WF), you need a reference location that is within half a degree latitude and half a degree longitude.

Make a call to a reverse geocoding backend, preferably one that returns structured information, and extract the town or city name.

Some geocoding backends are more suitable than others, so you might need to perform some tests.

## Ensuring the locality is near enough

After reverse geocoding the location and extracting the locality name, you should make a call to a geocoding service to get the location of the locality.
This is likely to be its center, not the position of the Plus Code, and could be some distance away.

You want it to be as close as possible, because other geocoding services are likely to position it slightly differently.
If it is very close to half a degree away, another geocoding service could result in the Plus Code being decoded to a different location.

Typically you should aim for a locality within a quarter of a degree - this is approximately 25km away (at the equator) so still quite a large range.

If the locality is near enough, you should display the local code and locality together.
The `shorten()` method in the OLC library may remove 2, 4, 6 or even 8 characters, depending on how close the reference location is.
Although all of these are valid, we recommend only removing the first 4 characters, so that Plus Codes have a consistent appearance.

# Summary

Supporting Plus Codes in search use cases should not be a complex exercise.