#!/bin/bash
# Check the format of the Python source files using YAPF.

python -m yapf --version >/dev/null 2>&1
if [ $? -eq 1 ]; then
  curl -o /tmp/get-pip.py https://bootstrap.pypa.io/get-pip.py && python /tmp/get-pip.py && pip install yapf
fi

# Run YAPF and check for diffs. If there aren't any, we're done.
DIFF=`python -m yapf --diff *py`
if [ $? -eq 0 ]; then
  echo -e "\e[32mPython files are correctly formatted\e[30m"
  exit 0
fi

# Format the files in place.
echo -e "\e[34mPython files have formatting errors -formatting in place\e[30m"
python -m yapf --in-place *py
exit 1
