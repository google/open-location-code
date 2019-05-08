#!/bin/bash


CLANG_FORMAT="clang-format-3.8"
if hash $CLANG_FORMAT 2>/dev/null; then
  echo "clang-format hashed"
elif hash clang-format 2>/dev/null; then
  echo "Cannot find clang-format-3.8, using clang-format"
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
  echo "Checking clang-format: $FILE"
  $CLANG_FORMAT $FILE | cmp $FILE >/dev/null
  if [ $? -ne 0 ]; then
    echo "[!] INCORRECT FORMATTING! $FILE" >&2
    $CLANG_FORMAT -i $FILE
    RETURN=1
  fi
done
exit $RETURN
