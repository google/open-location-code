#!/bin/bash
# Check the format of all the C files using clang-format.
# Run from within the c directory (or clang-format won't find it's config file).

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
      go run ../travis-utils/github_comments.go --pr "$TRAVIS_PULL_REQUEST" \
          --comment '**File has `clang-format` errors that must be fixed**. Here is a diff, or run `clang_check.sh`:'"<br><pre>$DIFF</pre>" \
          --file "c/$FILE" \
          --commit "$TRAVIS_PULL_REQUEST_SHA"
    fi
    RETURN=1
  fi
done
exit $RETURN

if [ $RETURN -ne 0 ]; then
  echo -e "\e[1;31mFiles have issues that must be addressed\e[0m"
else
  echo -e "\e[1;32mFiles pass all checks\e[0m"
fi
exit $RETURN
