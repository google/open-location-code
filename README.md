# Open Location Code

[![Build Status](https://github.com/google/open-location-code/actions/workflows/main.yml/badge.svg?branch=main)](https://github.com/google/open-location-code/actions/workflows/main.yml?query=branch%3Amain)
[![CDNJS](https://img.shields.io/cdnjs/v/openlocationcode.svg)](https://cdnjs.com/libraries/openlocationcode)

Open Location Code is a technology that gives a way of encoding location into a form that is easier to use than latitude and longitude. The codes generated are called Plus Codes, as their distinguishing attribute is that they include a "+" character.

The technology is designed to produce codes that can be used as a replacement for street addresses, especially in places where buildings aren't numbered or streets aren't named.

Plus Codes represent an area, not a point. As digits are added to a code, the area shrinks, so a full code is more precise than a short code.

Codes that are similar are located closer together than codes that are different.

A location can be converted into a code, and a full code Plus Code can be converted back to an area completely offline.

There are no data tables to lookup or online services required for full code Plus Codes. The algorithm is publicly available and can be used without restriction.

## Links

-   [Demonstration site](http://plus.codes/)
-   [Mailing list](https://groups.google.com/forum/#!forum/open-location-code)
-   [Comparison of Location Encoding Systems](./Documentation/Comparison.md)
-   [Introduction](./Documentation/Introduction.md)
-   [Plus Codes Specification](./Documentation/Plus%20Codes%20Specification.md)
-   [Open Location Code API Specification](./Documentation/Open%20Location%20Code%20API%20Specification.md)

## Description

Plus Codes are made up of a sequence of significant digits chosen from a set of 20. The digits in the code alternate between latitude and longitude. The first four digits describe a one degree latitude by one degree longitude area, aligned on degrees. Adding two further digits to the code, reduces the area to 1/20th of a degree by 1/20th of a degree within the previous area. And so on - each pair of digits reduces the area to 1/400th of the previous area.

As an example, the Parliament Buildings in Nairobi, Kenya are located at `6GCRPR6C+24`. `6GCR0000+` is the area from 2S 36E to 1S 37E. PR6C+24 is a 14 meter wide by 14 meter high area within `6GCR0000+`.

A "+" character is used after eight digits, to break the code up into two parts and to distinguish codes from postal codes.

There will be locations where a 10 digit code is not sufficiently precise, but refining it by a factor of 20 is i) unnecessarily precise and ii) requires extending the code by two digits. Instead, after 10 digits, the area is divided into a 4 × 5 grid and a single digit used to identify the grid square. A single grid refinement step reduces the area to approximately 3.5 × 2.8 meters.

Codes can be shortened relative to a location. This reduces the number of digits that must be remembered, by using a location to identify an approximate area, and then generating the nearest matching code. Shortening a code, if possible, will drop four or more digits from the start of the code. The degree to which a code can be shortened depends on the proximity of the reference location.

If the reference location is derived from a town or city name, it is dependent on the accuracy of the geocoding service. Although one service may place "Zurich" close to the Google office, another may move it by a hundred meters or more, and this could be enough to prevent the original code being recovered. Rather than a large city size feature to generate the reference location, it is better to use smaller, neighbourhood features, that will not have as much variation in their geocode results.

Specification for shortening codes is in the [Plus Codes Specification.md](https://github.com/google/open-location-code/blob/main/Documentation/Plus%20Codes%20Specification.md).

Recovering shortened codes works by providing the short code and a reference location. This does not need to be the same as the location used to shorten the code, but it does need to be nearby. Shortened codes always include the "+" character so it is simple to compute the missing component.

-   `8F+GG` omits six leading characters
-   `6C8F+GG` omits four leading characters

## Implementations

This repository includes implementations in various computer languages. Additionally, are linking to other known implementations.

| Language | Location | Validated against OLC API Spec 1.1.0 |
| -------- | -------- | ----------------- |
| c | [c](./c) | NO |
| common-lisp | [ralph-schleicher/open-location-code](https://github.com/ralph-schleicher/open-location-code) | NO |
| cpp | [cpp](./cpp) | NO |
| csharp | [JonMcPherson/open-location-code](https://github.com/JonMcPherson/open-location-code) | NO |
| dart | [dart](./dart) | NO |
| emacs | [davby02/olc](https://gitlab.liu.se/davby02/olc) | NO |
| go | [go](./go) | NO |
| java | [java](./java) | NO |
| js | [js](./js) | NO |
| plpgsql | [plpgsql](./plpgsql) | NO |
| python | [python](./python) | NO |
| ruby | [ruby](./ruby) | NO |
| rust | [rust](./rust) | NO |
| swift | [google/open-location-code-swift](https://github.com/google/open-location-code-swift) | NO |
| typescript | [tspoke/typescript-open-location-code](https://github.com/tspoke/typescript-open-location-code) | NO |
| visualbasic | [visualbasic](./visualbasic) | NO |