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

The build could also be extended to build for JavaScript and native platforms by adding additional targets.