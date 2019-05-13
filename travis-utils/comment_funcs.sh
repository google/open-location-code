#!/bin/bash
# If we are in TravisCI processing a pull request, send stdin to that pull
# request as a comment.

# Post a comment to a pull request.
# The comment should be the first argument, and will also be echoed to stdout.
function post_comment {
  BODY=$1
  echo "$BODY"
  if [ -z "$TRAVIS_PULL_REQUEST" ]; then
    # We're not even in TravisCI AFAICT.
    return 0
  fi
  if [ "$TRAVIS_PULL_REQUEST" != "false" ]; then
    # We're not processing a pull request.
    return 0
  fi
  # Remove bash colour characters or GitHub's comment JSON parser complains.
  CLEAN=`echo "$BODY" | sed -r "s/\x1B\[[0-9]+m//g"| sed -r "s/\n/  \n/g"`
  BODY="{\"body\": \"_Automated bot comment from TravisCI tests_  \n$CLEAN\"}"
  post_body_to_github "$BODY" "https://api.github.com/repos/${TRAVIS_REPO_SLUG}/issues/${TRAVIS_PULL_REQUEST}/comments"
}

# Post a comment to a specific file in a pull request.
# The file path should be the first argument, the body the second. The body will
# also be echoed to stdout.
function post_file_comment {
  FILE=$1
  BODY=$2
  echo "$BODY"
  if [ -z "$TRAVIS_PULL_REQUEST" ]; then
    # We're not even in TravisCI AFAICT.
    return 0
  fi
  if [ "$TRAVIS_PULL_REQUEST" != "false" ]; then
    # We're not processing a pull request.
    return 0
  fi
  # Remove bash colour characters or GitHub's comment JSON parser complains.
  CLEAN=`echo "$BODY" | sed -r "s/\x1B\[[0-9]+m//g"| sed -r "s/\n/  \n/g"`
  BODY="{\"body\": \"_Automated bot comment from TravisCI tests_  \n$CLEAN\", \"commit_id\": \"$TRAVIS_COMMIT\", \"path\": \"$1\", \"position\": 1}"
  post_body_to_github "$BODY" "https://api.github.com/repos/${TRAVIS_REPO_SLUG}/pulls/${TRAVIS_PULL_REQUEST}/comments"
}

function post_body_to_github {
  if [ -z "$GITHUB_TOKEN" ]; then
    echo -e "\e[31mNo auth token, cannot send to GitHub\e[30m"
    return 0
  fi
  
  STATUS=`curl -s -o /dev/null -w "%{http_code}" \
    -H "Authorization: token ${GITHUB_TOKEN}" -X POST \
    -d "$0" $1`
  if [ "$STATUS" != "200" ]; then
    echo -e "\e[31mFailed sending comment to GitHub\e[30m"
  fi
}
