#!/bin/bash
# Check the formatting of the Dart files and perform static analysis of the code
# with dartanalyzer.
# Run from within the dart directory.

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

# For every dart file, check the formatting.
for FILE in `find * | egrep "\.dart$"`; do
  FORMATTED=`$DART_FMT_CMD --set-exit-if-changed --fix "$FILE"`
  if [ $? -ne 0 ]; then
    # Running locally, we can just format the file. Use colour codes.
    echo -e "\e[1;34m"
    $DART_FMT_CMD --fix --overwrite $FILE
    echo -e "\e[0m"
  fi
  ANALYSIS=`$DART_ANALYZER_CMD "$FILE"`
  echo "$ANALYSIS" | grep "No issues found" >/dev/null
  if [ $? -ne 0 ]; then
    echo -e "\e[1;31mStatic analysis problems: $FILE\e[0m"
    echo "$ANALYSIS"
  fi
done

if [ $RETURN -ne 0 ]; then
  echo -e "\e[1;31mFiles have issues that must be addressed\e[0m"
else
  echo -e "\e[1;32mFiles pass all checks\e[0m"
fi
exit $RETURN
