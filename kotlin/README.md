# Kotlin specific version of Open Location Code (plus.codes)

## To setup:

```shell script
gradle wrapper --gradle-version 5.6.4
```

## To build:

```shell script
./gradlew clean build test
```

## To use:

This library is *not* currently published to a public maven repository.  You can publish it to a local maven repository using:

```shell script
./gradlew publishToMavenLocal
``` 

The JVM version can be used from Java as well and uses an API that is almost identical to the Java version.  

The build could also be extended to build other platforms by adding additional targets.

The main point of this port was to allow other Kotlin platforms from the same codebase.  Possibilities include:

* JavaScript
* iOS or Mac Framework (Objective-C / Swift)
* Android (via JVM version or as an Android library)
* Linux / Windows native
* Other native platforms