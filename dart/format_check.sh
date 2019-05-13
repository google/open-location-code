#!/bin/bash
# Check the formatting of the Dart files and perform static analysis of the code
# with dartanalyzer.
# Run from within the dart directory.

set -e
# Get the functions to allow posting to pull requests.
source ../travis-utils/comment_funcs.sh
set +e

DART_FMT_CMD=dartfmt
$DART_FMT_CMD --version >/dev/null 2>&1
if [ $? -ne 0 ]; then
  DART_FMT_CMD=/usr/lib/dart/bin/dartfmt
fi

DART_ANALYZER_CMD=dartanalyzer
$DART_ANALYZER_CMD --version >/dev/null 2>&1
if [ $? -ne 0 ]; then
  DART_ANALYZER_CMD=/usr/lib/dart/bin/dartanalyzer
fi

# Define the default return code.
RETURN=0

# For every dart file, check the formatting and perform static analysis.
for FILE in `find * | egrep "\.dart$"`; do
  echo Checking $FILE
  FORMATTED=`$DART_FMT_CMD --set-exit-if-changed --fix "$FILE"`
  if [ $? -ne 0 ]; then
    if [ -z "$TRAVIS" ]; then
      # Running locally, we can just format the file.
      echo -e "\e[1;34mFormatting: $FILE\e[30m"
      $DART_FMT_CMD --fix --overwrite $FILE
    else
      # On TravisCI, send a comment with the diff to the pull request.
      DIFF=`echo "$FORMATTED" | diff $FILE -`
      echo -e "\e[1;31mFile has formatting errors: $FILE\e[0m"
      echo "$DIFF"
      BODY='**File has `dartfmt` errors that must be fixed**. Here is a diff, or run `format_check.sh`:'
      BODY="$BODY\n<pre>$DIFF</pre>"
      RETURN=1
      post_file_comment "dart/$FILE" "$BODY"
    fi
  fi
  ANALYSIS=`$DART_ANALYZER_CMD "$FILE"`
  if [ $? -ne 0 ]; then
    echo -e "\e[1;31mStatic analysis problems: $FILE\e[0m"
    echo "$ANALYSIS"
    if [ "$TRAVIS" != "" ]; then
      # On TravisCI, send a comment with the diff to the pull request.
      BODY='**File has `dartanalyzer` errors that must be fixed**:'
      BODY="$BODY\n$ANALYSIS"
      RETURN=1
      post_file_comment "dart/$FILE" "$BODY"
    fi
  fi
done

if [ $RETURN -ne 0 ]; then
  echo -e "\e[1;32mFiles have issues that must be addressed\e[0m"
else
  echo -e "\e[1;32mFiles pass all checks\e[0m"
fi
exit $RETURN
