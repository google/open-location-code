#!/bin/bash
# Check the format of all the C files using clang-format.
# Run from within the C directory (or clang-format won't find it's config file).

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

# Get the bash functions to send comments back to the pull request on TravisCI.
. ../travis-utils/comment_funcs.sh

RETURN=0
for FILE in `find . | egrep "\.(c|cc|h)$"`; do
  DIFF=`diff $FILE <($CLANG_FORMAT $FILE)`
  if [ $? -ne 0 ]; then
    if [ -z "$TRAVIS" ]; then
      echo "Formatting $FILE"
      $CLANG_FORMAT -i $FILE
    else
      echo -e "\e[31m$FILE has formatting errors:\e[30m"
      echo "$DIFF"
      post_file_comment "$FILE" "clang-format reports formatting errors"
    fi
    RETURN=1
  fi
done
exit $RETURN
