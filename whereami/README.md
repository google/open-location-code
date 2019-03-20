# Display location information example

This page provides a simple example of how to get the location, convert it to a plus code and display it to the user.

All the messages and elements are in the HTML file, and the javascript file does all the work.

## Operation

The page fetches the latitude and longitude, and converts it to a 10-digit plus code.
If the device returned an accuracy, it is also displayed:

> Your location is:\
> 8FVC9G5G+5F\
> with accuracy +/- 1277 meters

## Optional Google API key

If you include a [Google API key](https://developers.google.com/maps/documentation/geocoding/get-api-key)
as a URL parameter called `key`, it will display the short address form of the plus code:

> Your location is:\
> 9G5G+5F Zürich, Switzerland\
> with accuracy +/- 1277 meters

## Copying

Like all files in this project, you are free to copy and modify these files, for example on your own website.

See the main project [LICENSE](https://github.com/google/open-location-code/blob/master/LICENSE) file.
