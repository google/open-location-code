#!/bin/bash
# Check formatting of C++ source files using clang-format.
# It will format the files in place.

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
$CLANG_FORMAT --version

if [ ! -f ".clang-format" ]; then
  echo ".clang-format file not found!"
  exit 1
fi

RETURN=0
:
for FILE in `ls *.cc *.h`; do
  DIFF=`diff $FILE <($CLANG_FORMAT $FILE)`
  if [ $? -ne 0 ]; then
    echo "Formatting $FILE" >&2
    $CLANG_FORMAT -i $FILE
    RETURN=1
  fi
done
exit $RETURN
