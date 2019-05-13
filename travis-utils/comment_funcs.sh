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
# * TRAVIS_PULL_REQUEST_SHA: This provides the pull request commit SHA that must
#     be used to send file-based comments back to the pull request


# Post a comment to a pull request.
# The comment should be the first argument, and will also be echoed to stdout.
function post_comment {
  COMMENT=`clean_body "$2"`
  if [ -z "$TRAVIS_PULL_REQUEST" ]; then
    # We're not even in TravisCI AFAICT.
    return 0
  fi
  if [ "$TRAVIS_PULL_REQUEST" == "false" ]; then
    # We're not processing a pull request.
    return 0
  fi
  BODY="{\"body\": \"_This is an automated bot comment from the TravisCI tests_  \n$COMMENT\"}"
  payload_to_github \
      "https://api.github.com/repos/${TRAVIS_REPO_SLUG}/issues/${TRAVIS_PULL_REQUEST}/comments" \
      "$BODY"
}

# Post a comment to a specific file in a pull request.
# The file path should be the first argument, the body the second. The body will
# also be echoed to stdout.
function post_file_comment {
  FILE=$1
  COMMENT=`clean_body "$2"`
  if [ -z "$TRAVIS_PULL_REQUEST" ]; then
    # We're not even in TravisCI AFAICT.
    return 0
  fi
  if [ "$TRAVIS_PULL_REQUEST" == "false" ]; then
    # We're not processing a pull request.
    return 0
  fi
  BODY="{\"body\": \"_This is an automated bot comment from the TravisCI tests_  \n$COMMENT\", \"commit_id\": \"$TRAVIS_PULL_REQUEST_SHA\", \"path\": \"$1\", \"position\": 1}"
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
  LOG=`mktemp`
  STATUS=`curl -s -o "$LOG" -w "%{http_code}" \
    -H "Authorization: token ${GITHUB_TOKEN}" -X POST \
    -d "$PAYLOAD" "$URL"`
  if [ "$STATUS" != "200" ]; then
    echo -e "\e[31mFailed sending comment to GitHub:\e[30m"
    cat "$LOG"
  fi
}

function clean_body {
  # Remove bash colour characters or GitHub's comment JSON parser will complain.
  # Convert new lines into "  \n" so they are formatted correctly in markdown.
  echo "$1" | sed -r "s/\x1B\[[0-9]+m//g"| sed -r "s/\n/  \n/g"
}
