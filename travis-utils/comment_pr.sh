#!/bin/bash
# If we are in TravisCI processing a pull request, send stdin to that pull
# request as a comment.

# Capture stdin.
STDIN=`cat`
# Echo it out so it gets caught by the TravisCI test log.
echo "$STDIN"
# Remove bash colour characters or GitHub's comment JSON parser complains.
STDIN_CLEAN=`echo $STDIN | sed -r "s/\x1B\[[0-9]+m//g"`

if [ -z "$TRAVIS_PULL_REQUEST" ]; then
  # We're not even in TravisCI AFAICT.
  exit 0
fi
if [ "$TRAVIS_PULL_REQUEST" != "false" ]; then
  # We're in a pull request.
  STATUS=`curl -s -o /dev/null -w "%{http_code}" \
    -H "Authorization: token ${GITHUB_TOKEN}" -X POST \
    -d "{\"body\": \"$STDIN_CLEAN\"}" \
    "https://api.github.com/repos/${TRAVIS_REPO_SLUG}/issues/${TRAVIS_PULL_REQUEST}/comments"`
  if [ "$STATUS" != "200" ]; then
    echo -e "\e[31mFailed sending comment to GitHub\e[30m"
  fi
fi
