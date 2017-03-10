# Java Open Location Code library

## Building

Create an empty `build` directory:

```shell
mkdir build
```

Compile the `com/google/openlocationcode/OpenLocationCode.java` file and then
package it as a jar file:

```shell
javac -d build com/google/openlocationcode/OpenLocationCode.java
cd build
jar cvf OpenLocationCode.jar com/google/openlocationcode/OpenLocationCode*.class
cd ..
```
That's it - you'll have a jar file in `build/OpenLocationCode.jar`.

## Testing

Download the `junit` and `hamcrest` jar files from [their repository](https://github.com/junit-team/junit4/wiki/Download-and-Install)
and place them somewhere.

(This will assume you downloaded `junit-41.2.jar` and `hamcrest-core-1.3.jar`)

Build the `OpenLocationCode.jar` file as above.

Add all three files to your `CLASSPATH` variable (obviously use the real paths to the files):

```shell
CLASSPATH=$CLASSPATH:build/OpenLocationCode.jar:/path/to/junit-4.12.jar:/path/to/hamcrest-core-1.3.jar
```

Compile the test classes:

```shell
javac -cp $CLASSPATH -d build com/google/openlocationcode/tests/*java
```

Run the tests. Note that we need to use the `-cp` argument to give the location of the test classes and the test data files:

```shell
java -cp $CLASSPATH:build:../test_data: org.junit.runner.JUnitCore com.google.openlocationcode.tests.EncodingTest com.google.openlocationcode.tests.PrecisionTest com.google.openlocationcode.tests.ShorteningTest com.google.openlocationcode.tests.ValidityTest
```
