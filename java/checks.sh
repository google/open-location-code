#!/bin/bash
# Check the formatting of the Java files.
# Run from within the java directory.

RETURN=0

# Check the formatting using the Maven spotless plugin (calling google-java-format).
# Maven outputs all the downloads, so just pull out the ERROR lines, and the
# ones with PMD since it logs it's errors at INFO level.
SPOTLESS=`mvn -B spotless:check | egrep "ERROR|PMD"`
if [ $? -ne 0 ]; then
  if [ -z "$TRAVIS" ]; then
    # Running locally, we can just format the file. Use colour codes.
    echo -e "\e[1;34m Reformatting files"
    mvn spotless:apply
    echo -e "\e[0m"
  else
    # On TravisCI, send a comment with the diff to the pull request.
    echo -e '\e[1;31mProject has formatting errors, fix with `mvn spotless:apply`\e[0m'
    go run ../travis-utils/github_comments.go --pr "$TRAVIS_PULL_REQUEST" \
        --comment '**Project has formatting errors, fix with `mvn spotless:apply`. Here is the report:'"<br><pre>$FORMATTING</pre>"
    RETURN=1
  fi
fi

# Do the static code analysis using the PMD plugin.
# Strip out the download messages.
ANALYSIS=`mvn -B pmd:check | egrep -v Download`
if [ $? -ne 0 ]; then
  if [ -z "$TRAVIS" ]; then
    # Running locally, output the errors.
    echo -e "\e[1;31m Static analysis errors - \e[0m"
    echo "$ANALYSIS"
  else
    # On TravisCI, send a comment with the diff to the pull request.
    echo -e "\e[1;31mProject has analysis errors:\e[0m"
    echo "$ANALYSIS"
    RETURN=1
    go run ../travis-utils/github_comments.go --pr "$TRAVIS_PULL_REQUEST" \
        --comment '**Project has errors that must be fixed**. Here is the report:'"<br><pre>$ANALYSIS</pre>"
  fi
fi

# And run the Maven tests.
mvn test
if [ $? -ne 0 ]; then
  RETURN=1
fi

# Exit, returning 1 if either command failed.
exit $RETURN
