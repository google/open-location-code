# Field Collection of Plus Code Locations
[<img src="https://play.google.com/intl/en_us/badges/images/generic/en_badge_web_generic.png" width="200">](https://play.google.com/store/apps/details?id=org.odk.collect.android)

## Summary

Collecting locations of equipment, buildings, homes etc from the field, and obtaining the Plus Codes, is a common problem.

[Open Data Kit](https://opendatakit.org) is a suite of free and open source software to support collecting, managing and using data. [Open Data Kit Collect](https://play.google.com/store/apps/details?id=org.odk.collect.android) (ODK Collect) is a free, open source app available in the Google Play Store for customizable data collection in an offline environment.

This document explains how to get started with ODK to collect location data and convert it to Plus Codes.

**Note:** This process will collect latitude and longitude and convert them to global Plus Codes, e.g. 8FVC9G8F+6W.
Converting these to Plus Code addresses (9G8F+6W Zurich, Switzerland) is out of scope of this data collection. (One way it could be done is using the [Google Maps Geocoding API](https://developers.google.com/maps/documentation/geocoding/intro).)

## Overview

First we will define a [form](https://docs.opendatakit.org/form-design-intro/) that specifies what data we want, and then use [ODK Collect](https://docs.opendatakit.org/collect-intro/), an Android app, to collect filled in forms.

ODK Collect saves location information as latitude and longitude, so the final step will be to convert those to Plus Codes using the [Plus Code add-on for Google Sheets](https://gsuite.google.com/marketplace).

## Requirements

* ODK Collect runs on Android devices
* The field workers will need Google accounts (we're going to use Google Drive and Sheets).

## Alternatives

Other options for collecting this data might be to use Google Maps - manually long pressing on the map displays an address card, and expanding that shows the Plus Code.

Alternatively, you could write an HTML5 web app or develop another mobile app.
These could do the conversion from GPS coordinates to Plus Codes directly.
However, we think that using Open Data Kit provides the fastest route to general functionality.

## Using Open Data Kit

Here is a [description of using ODK with Google Drive and Sheets](https://www.google.com/earth/outreach/learn/odk-collect-and-google-drive-integration-to-store-and-manage-your-data).

This procedure can be followed exactly, or a slightly easier method to define the form is described below.

## Online Form Editor

That document uses a Google Sheet to define the form.
This can be complicated to test and debug.
A simpler way is to use the [online form editor](https://build.opendatakit.org/).

This provides a drag and drop method to sequence the form questions and set the field names, list of options etc.

You can build a basic flow with location collection, and include additional metadata such as the time of collection, the phone number etc.

You will need to create a blank Google Sheet.
Name one of the tabs "Form Submissions" or similar, copy the URL of that tab and set it as the `submission URL` in the form (using Edit -> Form Properties).

The, save the form and export it (with File -> Export to XML), and then transfer that XML file to your Google Drive account. (Putting it in a folder together with the spreadsheet will make sharing those files to your field workers easy.)

### Location Notes

You can select whether to use Google Maps or OpenStreetMap in the general settings.
You can also select whether to display the street map, or aerial imagery.

ODK Collect will only use GPS locations when it can see a minimum number of satellites.
If your field workers will be using it indoors, then the GPS location may not be available.
Instead, you can set the field to not use GPS but allow a [user entered location](https://docs.opendatakit.org/form-question-types/#geopoint-with-user-selected-location) - but that will not collect accuracy or altitude, and may also be inaccurate.

A better solution is to use the manual location as a fallback to GPS.
You can have one question that uses the GPS location (with or without a map), and a second question that gets the location manually, and only show that question if the GPS is not available, or the location accuracy was poor.

If using the online editor, enter the following in the **Relevance** field for the manual location field:
```
not(boolean(/data/gps_location)) or number(/data/gps_location)>15
```

(This assumes the data name of the GPS location field is `gps_location`.)

If building your form in a spreadsheet, put the following in the **survey** tab:

| type | name | label | relevant | appearance |
|------|------|-------|----------|------------|
| geopoint | gps_location | GPS location |  | maps
| geopoint | manual_location | Manual location | `not(boolean(${gps_location})) or number(${gps_location})>15` | placement-map

# Configuring ODK Collect

Install and configure ODK Collect as described in the [document](https://www.google.com/earth/outreach/learn/odk-collect-and-google-drive-integration-to-store-and-manage-your-data).

The document also describes how to use it and upload completed forms to the Google Sheet.

# Converting Locations To Plus Codes

ODK uploads locations to the sheet using three fields:
* location (decimal degrees)
* altitude (set to zero for manual locations)
* accuracy (set to zero for manual locations)

To convert these to Plus Codes, install the Google Sheets Plus Code add-on from the [G Suite Marketplace](https://gsuite.google.com/marketplace).
You can convert a column of locations into their corresponding Plus Codes using the formula:
```
=PLUSCODE(B:B)
```
This will use the default precision code length, 10 digits.
If you need a different precision, specify the code length in the formula:
```
=PLUSCODE(B:B, 11)
```
Installing and using the Google Sheets Plus Codes add-on is covered in a series of videos:

[![Google Sheets Plus Codes add-on video playlist](https://i.ytimg.com/vi/min-u1w4SOQ/hqdefault.jpg)](https://www.youtube.com/watch?v=n9kJC5qVeS0&list=PLaBfOq9xgeeBgOLyKnw8kvpFpZ_9v_sHa)
