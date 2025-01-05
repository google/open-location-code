# Open Location Code Frequently Asked Questions

## Table Of Contents
- [Open Location Code Frequently Asked Questions](#open-location-code-frequently-asked-questions)
  - [Table Of Contents](#table-of-contents)
  - [Background](#background)
    - ["Plus Codes" or "Open Location Code"?](#plus-codes-or-open-location-code)
    - [What are they for?](#what-are-they-for)
    - [Why not use street addresses?](#why-not-use-street-addresses)
    - [Why not use latitude and longitude?](#why-not-use-latitude-and-longitude)
    - [Why is Open Location Code based on latin characters?](#why-is-open-location-code-based-on-latin-characters)
  - [Plus Code digital addresses](#plus-code-digital-addresses)
    - [Reference location dataset](#reference-location-dataset)
    - [Plus Code addresses in Google Maps](#plus-code-addresses-in-google-maps)
    - [Plus Code addresses of high-rise buildings](#plus-code-addresses-of-high-rise-buildings)
    - [Plus Code precision](#plus-code-precision)



## Background

### "Plus Codes" or "Open Location Code"?

The software library (and this GitHub project) is called "Open Location Code", because it's a location code that is open source.
The codes it generates are called "Plus Codes" because they have a plus sign in them.

### What are they for?

Plus Codes provide a short reference to any location.
We created them to provide a way to refer to any location, regardless of whether there are named roads, unnamed roads, or no roads at all.

### Why not use street addresses?

A lot of rural areas can be far away from roads, and people still want to be able to refer to specific locations.
Also, at lot of the roads in the world don't have names, and so locations along those roads don't have addresses.
There is an estimate by the World Bank that the majority of urban roads don't have names.

Street-based addressing projects are expensive and slow, and haven't made much of a dent in this problem.
Plus Codes can be assigned rapidly and because they can be used immediately can solve the addressing problem quickly and cheaply.

### Why not use latitude and longitude?

One answer is that if latitude and longitude were a practical solution, people would already be using them.
The problem with latitude and longitude is that they are two numbers, possibly signed, with a lot of digits, and the order is important.

But latitude and longitude, and many other systems such as MGRS, geocodes, etc, also have the problem that they do not look like addresses.
We all know what an address looks like - a collection of references from less detailed to more detailed, typically: country, state, city, street, and house.
This hierarchy is important since it makes it easy to determine if something is near or far without having to understand the whole thing.
You can tell if it's in a different city without having to know the street name.

### Why is Open Location Code based on latin characters?

We are aware that many of the countries where Plus Codes will be most useful use non-Latin character sets, such as Arabic, Chinese, Cyrillic, Thai, Vietnamese, etc.
We selected Latin characters as the most common second-choice character set in these locations.
We considered defining alternative Open Location Code alphabets in each character set, but this would result in codes that would be unusable to visitors to that region, or internationally.

## Plus Code digital addresses

Plus Code digital addresses use known address information, like country, state, city, and then use the Plus Code to provide the final information.
Typically converting a Plus Code to a Plus Code address removes the first four digits from the code to shorten it to just six digits.

Any city or place name within approximately 30-50 km can be used to recover the original location.

### Reference location dataset

The open source libraries support conversion to/from addresses using the latlng of the reference location.
Callers will need to convert place names to/from latlng using a geocoding system.

Providing a global dataset isn't within scope of this project.
For a potential free alternative, see [Open Street Map](https://wiki.openstreetmap.org/) and derived geocoding service [Nominatim](https://nominatim.org/).

### Plus Code addresses in Google Maps

Google Maps displays Plus Code addresses on all entries.
It does this by using the location of the business for the Plus Code, and then using the place name to shorten the Plus Code to a more convenient form.

If the listing is managed by the business owner, it will try to use a place name from the address, otherwise it will use Google's best guess for the place name. (Google tries to pick names for cities rather than suburbs or neighbourhoods.)

If you think a different place name would be better, you can use that, and as long as Google knows about that place name the Plus Code address should work.

### Plus Code addresses of high-rise buildings

Plus Codes don't include the floor or apartment in high-rise buildings.
If you live in a multi-storey building located at "9G8F+6W, Zürich, Switzerland", think of the Plus Code as like the street name and number, and put your floor or apartment number in front: "Fourth floor, 9G8F+6W, Zürich, Switzerland"

The reason for this is that Plus Codes need to be created without knowing specifically what is there.
The other reason is that addresses in high-rise buildings are assigned differently in different parts of the world, and we don't need to change that.

### Plus Code precision

The precision of a Plus Code is indicated by the number of digits after the "+" sign.

*  Two digits after the plus sign is an area roughly 13.7 by 13.7 meters;
*  Three digits after the plus sign is an area roughly 2.7 by 3.5 meters;
*  Four digits after the plus sign is an area roughly 0.5 by 0.8 meters.

Apps can choose the level of precision they display, but should bear in mind the likely precision of GPS devices like smartphones, and the increased difficulty of remembering longer codes.

One reason to use three or four digits after the plus sign might be when addressing areas that contain small dwellings, to avoid having multiple dwellings with the same Plus Code address.
