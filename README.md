Open Location Code
==================

[![Build Status](https://github.com/google/open-location-code/actions/workflows/main.yml/badge.svg?branch=main)](https://github.com/google/open-location-code/actions/workflows/main.yml?query=branch%3Amain)
[![CDNJS](https://img.shields.io/cdnjs/v/openlocationcode.svg)](https://cdnjs.com/libraries/openlocationcode)

Open Location Code is a technology that gives a way of encoding location into a form that is
easier to use than latitude and longitude. The codes generated are called plus codes, as their
distinguishing attribute is that they include a "+" character.

The technology is designed to produce codes that can be used as a replacement for street addresses, especially
in places where buildings aren't numbered or streets aren't named.

Plus codes represent an area, not a point. As digits are added
to a code, the area shrinks, so a long code is more precise than a short
code.

Codes that are similar are located closer together than codes that are
different.

A location can be converted into a code, and this (full) code can be converted back to a location completely offline, without any data tables to lookup or online services required.

Codes can be shortened for easier communication, in which case they can be used regionally or in combination with a reference location that all users of this short code need to be aware of. If the reference location is given in form of a location name, use of a geocoding service might be necessary to recover the original location.

Algorithms to
* encode and decode full codes,
* shorten them relative to a reference location, and
* recover a location from a short code and a reference location given as latitude/longitude pair 

are publicly available and can be used without restriction. Geocoding services are not a part of the Open Location Code technology.

Links
-----
 * [Demonstration site](http://plus.codes/)
 * [Mailing list](https://groups.google.com/forum/#!forum/open-location-code)
 * [Comparison of existing location encoding systems](https://github.com/google/open-location-code/wiki/Evaluation-of-Location-Encoding-Systems)
 * [Open Location Code definition](https://github.com/google/open-location-code/blob/master/docs/olc_definition.adoc)

Description
-----------

Codes are made up of a sequence of digits chosen from a set of 20. The
digits in the code alternate between latitude and longitude. The first
four digits describe a one degree latitude by one degree longitude
area, aligned on degrees. Adding two further digits to the code,
reduces the area to 1/20th of a degree by 1/20th of a degree within the
previous area. And so on - each pair of digits reduces the area to
1/400th of the previous area.

As an example, the Parliament Buildings in Nairobi, Kenya are located at
6GCRPR6C+24. 6GCR is the area from 2S 36E to 1S 37E. PR6C+24 is a 14 meter
wide by 14 meter high area within 6GCR.

A "+" character is used after eight digits, to break the code up into two parts
and to distinguish codes from postal codes.

There will be locations where a 10-digit code is not sufficiently precise, but
refining it by a factor of 20 is i) unnecessarily precise and ii) requires extending
the code by two digits. Instead, after 10 digits, the area is divided
into a 4x5 grid and a single digit used to identify the grid square. A single
grid refinement step reduces the area to approximately 3.5x2.8 meters.

Codes can be shortened relative to a location. This reduces the number of digits
that must be remembered, by using a location to identify an approximate area,
and then generating the nearest matching code. Shortening a code, if possible,
will drop four or more digits from the start of the code. The degree to which a
code can be shortened depends on the proximity of the reference location.

If the reference location is derived from a town or city name, it is dependent
on the accuracy of the geocoding service. Although one service may place
"Zurich" close to the Google office, another may move it by a hundred meters or
more, and this could be enough to prevent the original code being recovered.
Rather than a large city size feature to generate the reference location, it is
better to use smaller, neighbourhood features, that will not have as much
variation in their geocode results.

Guidelines for shortening codes are in the [wiki](https://github.com/google/open-location-code/wiki/Guidance-for-shortening-codes).

Recovering shortened codes works by providing the short code and a reference
location. This does not need to be the same as the location used to shorten the
code, but it does need to be nearby. Shortened codes always include the "+"
character so it is simple to compute the missing component.

 * 8F+GG is missing six leading characters
 * 6C8F+GG is missing four leading characters

Example Code
------------

The subdirectories contain sample implementations and tests for different
languages. Each implementation provides the following functions:

 * Test a code to see if it is a valid sequence
 * Test a code to see if it is a valid full code
   (not all valid sequences are valid full codes)
 * Encode a latitude and longitude to a standard accuracy
   (14 meter by 14 meter) code
 * Encode a latitude and longitude to a code of any length
 * Decode a code to its coordinates: low, high and center
 * Shorten a full code relative to a location
 * Extend a short code relative to a location
