Android Open Location Code Demonstrator
=======================================

This is the source code for an Android app that uses
[Open Location Code](https://maps.google.com/pluscodes/) and displays them on a
map.

It displays the current location, computes the code for that location, and uses
a bundled set of place names to shorten the code to a more convenient form.
Currently all the place names exist within Cape Verde. Other place names can be
added to the source.

Using a bundled set of places means that determining the current address, and
locating an entered address will work offline.

This project has been structured to be used with
[Android Studio](https://developer.android.com/studio/index.html).

An Open Location Code JAR file is in the directory `android/libs`. If the core library
is updated, you will need to update this JAR file.
