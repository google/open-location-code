#!/bin/bash
# Check the formatting of the Dart files.

DARTCMD=dartfmt
$DARTCMD --version >/dev/null 2>&1
if [ $? -ne 0 ]; then
  DARTCMD=/usr/lib/dart/bin/dartfmt
fi

DIFF=`$DARTCMD --dry-run --set-exit-if-changed --fix .`
if [ $? -eq 0 ]; then
  echo -e "\e[1;32mDart files are formatted correctly!\e[30m"
  exit 0
fi

if [ -z "$TRAVIS" ]; then
  # Not running on TravisCI, so format the files in place.
  echo -e "\e[1;34mDart files have formatting errors - formatting in place\e[30m"
  $DARTCMD --fix --overwrite .
else
  echo -e "\e[1;31mDart files have formatting errors\e[30m"
  echo -e "\e[1;31mThese must be corrected using format_check.sh\e[30m"
  echo "$DIFF"
fi
