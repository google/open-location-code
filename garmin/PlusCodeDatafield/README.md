# Plus code datafield for Garmin Connect IQ devices.

[<img src="https://developer.garmin.com/img/connect-iq/brand/available-badge.svg" alt="Drawing" width=200 style="width: 200px;"/>](https://apps.garmin.com/en-US/apps/74d90879-fbac-48e7-8405-28af2a0a55a7#0)


Plus codes are short codes you can use to refer to a place, that are easier
to use than latitude and longitude. They were designed to provide an
address-like solution for the areas of the world where street addresses do not
exist or are not widely known. Plus codes are free and the software is open
source. See the [demo site](https://plus.codes) or the
[Github project](https://github.com/google/open-location-code).

This datafield displays the plus code for your current location. It doesn't
use any network because plus codes can be computed offline.

Codes are displayed with the first four digits (the area code) small, and the
remaining digits larger (this is the local code).

For example, it might display:

| 8FVC |
| ------- |
| **8FXR+QH** |

To tell someone within 30-50 km (20-30 miles), you can just tell them 8FXR.
If they are further away, you can tell them the whole code, or you can give
them the second part and a nearby town or city. (For example, 8FXR+QH Zurich.)

They can enter the code into Google Maps, or into
[plus.codes](https://plus.codes).

The code will fade if the location accuracy is poor or the GPS signal is lost.

The code precision is approximately 14 by 14 meters.

A built version of the datafield is available on the Garmin Connect IQ
[app store](https://apps.garmin.com/en-US/apps/74d90879-fbac-48e7-8405-28af2a0a55a7#0),
or you can build your own version.

## Build and Installation

If you're using the
[normal](https://developer.garmin.com/connect-iq/programmers-guide/getting-started/)
Garmin development process, just open this directory in Eclipse.

If running on Linux, see below for instructions on getting your machine
set up and the Garmin Connect IQ tools installed. Once done, you should be
able to compile the app with:

```shell
monkeyc -w -y developer_key.der -m manifest.xml -z resources/strings.xml -z resources/drawables.xml -z resources/layouts.xml -o bin/PlusCodeDatafield.prg source/*
```

That will create a file called `PlusCodeDatafield.prg` in the `bin` directory.
Copy that file to the `Garmin/Apps` directory on your device. Restart it, and
you should be able to add it to your data screens!

## Supported Devices

All languages are supported.

The following devices are supported:

* D2 Bravo
* Edge 520, 820, 1000 (including Explore)
* fēnix Chronos, fēnix3, fēnix5
* tactix Bravo
* quatix 3
* Forerunner 230/235/630/735xt/920xt
* Vivoactive, Vivoactive HR
* Epix
* Oregon 700/750/750t
* Rino 750/750t

## Logging issues

Create an issue on the project site by
[clicking here](https://github.com/google/open-location-code/issues/new?title=Issue%20with%20Garmin%20datafield&body=Provide%20your%20device%20model%20and%20what%20the%20problem%20is.%20Including%20screenshots%20would%20really%20help.&labels=garmin).

## Using Connect IQ on Linux

See [this overview](http://blog.aaronboman.com/programming/connectiq/2014/11/13/the-garmin-connect-iq-sdk-on-ubuntu-linux/)
for general information.

There seem to have been some changes to the `monkeyc` command since that blog
article was published:

* You must include your [developer key](https://developer.garmin.com/connect-iq/programmers-guide/getting-started/#generatingadeveloperkeyciq1.3) with the `-y` option
* You must include the source files on the command line 
