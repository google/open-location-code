Building the Open Location Code JAR file
==

Using the source in the
[Java](https://github.com/google/open-location-code/blob/master/java/com/google/openlocationcode/OpenLocationCode.java)
implementation, build a JAR file and put it in this location.

--

Assuming you've downloaded this repository locally:

```
cd open-location-code-master/java
javac com/google/openlocationcode/OpenLocationCode.java
jar -cfM ./openlocationcode.jar com/google/openlocationcode/OpenLocationCode\$CodeArea.class com/google/openlocationcode/OpenLocationCode.class
```

The `.jar` file is in the `open-location-code-master/java` directory

If working with Android Studio, add `openlocationcode.jar` to `/{PROJECT_NAME}/{APP}/libs` *(you may need to create the `/libs` folder)* 

Why don't we include a JAR file here?
--

Basically, we want to make sure that we don't fix a bug in the Java implementation and forget to
update this JAR file.

Why don't we have a Maven repository?
--

So far, we've only had one request. If you would like to be able to pull the library via Maven,
file an issue and we'll consider it.
