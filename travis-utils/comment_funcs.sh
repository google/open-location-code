#!/bin/bash
# Provides bash functions to send comments to GitHub pull requests.
# * post_comment sends a comment to the pull request conversation log.
# * post_file_comment sends a comment to a specific file in the pull request.
#
# This requires a number of environment variables to be set:
#
# * GITHUB_TOKEN: This is the authentication token by a user, used to send the
#     comments. It's set in the TravisCI project settings.
# * TRAVIS_PULL_REQUEST: Provides the pull request number. If it is "false",
#     signifies that we are in a push build.
# * TRAVIS_REPO_SLUG: Provides the path to the repository
#     ("google/open-location-code").

# Post a comment to a pull request.
# The comment should be the first argument, and will also be echoed to stdout.
function post_comment {
  BODY=$1
  echo "$BODY"
  if [ -z "$TRAVIS_PULL_REQUEST" ]; then
    # We're not even in TravisCI AFAICT.
    echo "Not even in TravisCI"
    return 0
  fi
  if [ "$TRAVIS_PULL_REQUEST" == "false" ]; then
    # We're not processing a pull request.
    echo "Not in a pull request"
    return 0
  fi
  # Remove bash colour characters or GitHub's comment JSON parser will complain.
  CLEAN=`echo "$BODY" | sed -r "s/\x1B\[[0-9]+m//g"| sed -r "s/\n/  \n/g"`
  BODY="{\"body\": \"_Automated bot comment from TravisCI tests_  \n$CLEAN\"}"
  payload_to_github \
      "https://api.github.com/repos/${TRAVIS_REPO_SLUG}/issues/${TRAVIS_PULL_REQUEST}/comments" \
      "$BODY"
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
    echo "Not even in TravisCI"
    return 0
  fi
  if [ "$TRAVIS_PULL_REQUEST" == "false" ]; then
    # We're not processing a pull request.
    echo "Not in a pull request"
    return 0
  fi
  # Don't use TRAVIS_COMMIT, it's not the PR commit number.
  HEAD_COMMIT=`git show FETCH_HEAD --pretty="format:%H"|head -1`
  # Remove bash colour characters or GitHub's comment JSON parser will complain.
  CLEAN=`echo "$BODY" | sed -r "s/\x1B\[[0-9]+m//g"| sed -r "s/\n/  \n/g"`
  BODY="{\"body\": \"_Automated bot comment from TravisCI tests_  \n$CLEAN\", \"commit_id\": \"$HEAD_COMMIT\", \"path\": \"$1\", \"position\": 1}"
  payload_to_github \
      "https://api.github.com/repos/${TRAVIS_REPO_SLUG}/pulls/${TRAVIS_PULL_REQUEST}/comments" \
      "$BODY"
}

# Post a payload to a GitHub API URL.
# The first argument is the URL, the second is the payload.
function payload_to_github {
  URL=$1
  PAYLOAD=$2
  if [ -z "$URL" ]; then
    echo -e "\e[31mNo URL to post to GitHub\e[30m"
    return 0
  fi
  if [ -z "$PAYLOAD" ]; then
    echo -e "\e[31mNo payload to post to GitHub\e[30m"
    return 0
  fi
  if [ -z "$GITHUB_TOKEN" ]; then
    echo -e "\e[31mNo auth token, cannot send to GitHub\e[30m"
    return 0
  fi
  echo "Trying to send to GitHub..."
  echo "$URL"
  echo "$BODY"
  # STATUS=`curl -s -o /dev/null -w "%{http_code}" 
  curl \
    -H "Authorization: token ${GITHUB_TOKEN}" -X POST \
    -d "$PAYLOAD" "$URL"
  if [ "$STATUS" != "200" ]; then
    echo -e "\e[31mFailed sending comment to GitHub\e[30m"
  fi
}
