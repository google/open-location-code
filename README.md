Open Location Code
==================

Open Location Codes are a way of encoding location into a form that is
easier to use than latitude and longitude.

They are designed to be used as a replacement for street addresses, especially
in places where buildings aren't numbered or streets aren't named.

Open Location Codes represent an area, not a point. As characters are added
to a code, the area shrinks, so a long code is more accurate than a short
code.

Codes that are similar are located closer together than codes that are
different.

A location can be converted into a code, and a code can be converted back
to a location completely offline.

There are no data tables to lookup or online services required. The
algorithm is publicly available and can be used without restriction.

Links
-----
 * [Demonstration site](http://plus.codes/)
 * [Mailing list](https://groups.google.com/forum/#!forum/open-location-code)
 * [Comparison of existing location encoding systems](https://github.com/google/open-location-code/blob/master/docs/comparison.adoc)
 * [Open Location Code definition](https://github.com/google/open-location-code/blob/master/docs/olc_definition.adoc)

Description
-----------

Codes are made up of a sequence of characters chosen from a set of 20. The
characters in the code alternate between latitude and longitude. The first
four characters describe a one degree latitude by one degree longitude
area, aligned on degrees. Adding two further characters to the code,
reduces the area to 1/20th of a degree by 1/20th of a degree within the
previous area. And so on - each pair of characters reduces the area to
1/400th of the previous area.

As an example, the Parliament Buildings in Nairobi, Kenya are located at
6GCR.PR6C24. 6GCR is the area from 2S 36E to 1S 37E. PR6C24 is a 14 meter
wide by 14 meter high area within 6GCR.

Because codes can appear similar to telephone numbers or postcodes, they can
be prefixed with a "+" character to disambiguate them.

A "." character is used to break the code up into two parts, in the same way
that spaces are used to break up telephone numbers to make them easier to
remember and communicate. It also makes it easier to process code fragments.

From character 11 on in the code, the code can be refined using a single
character. This is because there will be locations where a 10 character code is
not sufficiently accurate. After 10 characters, instead of dividing the latitude
and longitude range by 20 and adding a character for each, the area is divided
into a 4x5 grid and a single character used to identify the grid square.

A single grid refinement step reduces the area to approximately 3.5x2.8 meters.

Codes can be shortened relative to a location. This reduces the amount of code
that is necessary to be remembered, by using the location to identify an
approximate area, and then generating the nearest matching code. Only codes
whose length is 10 (standard accuracy) or 11 (one grid refinement) can be
shortened. Shortening a code, if possible, will drop four or more characters
from the start of the code. The degree to which a code can be shortened depends
on the proximity of the reference location.

If the reference location is derived from a town or city name, it is dependent
on the accuracy of the geocoding service. Although one service may place
"Zurich" close to the Google office, another may move it by a hundred meters or
more, and this could be enough to prevent the original code being recovered.
Rather than a large city size feature to generate the reference location, it is
better to use smaller, neighbourhood features, that will not have as much
variation in their geocode results.

Recovering shortened codes works by providing the short code and a reference
location. This does not need to be the same as the location used to shorten the
code, but it does need to be nearby. The short codes will be modified according
to the following pattern, where S represents the supplied characters, and R are
the recovered characters:

 * SSSS    -> RRRR.RRSSSS
 * SSSSS   -> RRRR.RRSSSSS
 * SSSSSS  -> RRRR.SSSSSS
 * SSSSSSS -> RRRR.SSSSSSS

Example Code
------------

The subdirectories contain sample implementations and tests for different
languages. Each implementation provides the following functions:

 * Test an code to see if it is a valid sequence
 * Test an code to see if it is a valid full code. Not all valid sequences
are valid full codes
 * Encode a latitude and longitude to a standard accuracy (14 meter by 14
meter) code
 * Encode a latitude and longitude to any length code
 * Decode a code to it's coordinates - low, high and center
 * Shorten a full code relative to a location
 * Extend a short code relative to a location.
