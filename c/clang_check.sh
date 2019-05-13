#!/bin/bash
# Check the format of all the C files using clang-format.
# Run from within the c directory (or clang-format won't find it's config file).

set -e
# Get the functions to allow posting to pull requests.
source ../travis-utils/comment_funcs.sh
set +e

go version
git log -n 1

CLANG_FORMAT="clang-format-5.0"
if hash $CLANG_FORMAT 2>/dev/null; then
  echo "clang-format hashed"
elif hash clang-format 2>/dev/null; then
  echo "Cannot find $CLANG_FORMAT, using clang-format"
  CLANG_FORMAT="clang-format"
else
  echo "Cannot find clang-format"
  exit 1
fi

if [ ! -f ".clang-format" ]; then
  echo ".clang-format file not found!"
  exit 1
fi

RETURN=0
for FILE in `find * | egrep "\.(c|cc|h)$"`; do
  DIFF=`diff $FILE <($CLANG_FORMAT $FILE)`
  if [ $? -ne 0 ]; then
    if [ -z "$TRAVIS" ]; then
      echo -e "\e[1;34mFormatting $FILE\e[0m"
      $CLANG_FORMAT -i $FILE
    else
      echo -e "\e[1;31m$FILE has formatting errors:\e[0m"
      echo "$DIFF"
      post_file_comment "c/$FILE" "clang-format reports formatting errors\n<pre>$DIFF<pre>"
    fi
    RETURN=1
  fi
done
exit $RETURN

if [ $RETURN -ne 0 ]; then
  echo -e "\e[1;32mFiles have issues that must be addressed\e[0m"
else
  echo -e "\e[1;32mFiles pass all checks\e[0m"
fi
exit $RETURN
