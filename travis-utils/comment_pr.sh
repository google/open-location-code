#!/bin/bash
# If we are in TravisCI processing a pull request, send stdin to that pull
# request as a comment.

# Capture stdin.
STDIN=`cat`
# Echo it out so it gets caught by the TravisCI test log.
echo "$STDIN"

if [ -z "$TRAVIS_PULL_REQUEST" ]; then
  # We're not even in TravisCI AFAICT.
  exit 0
fi
if [ "$TRAVIS_PULL_REQUEST" != "false"]; then
  # We're in a pull request.
  curl -H "Authorization: token ${GITHUB_TOKEN}" -X POST \
    -d "{\"body\": \"$STDIN\"}" \
    "https://api.github.com/repos/${TRAVIS_REPO_SLUG}/issues/${TRAVIS_PULL_REQUEST}/comments"
fi
