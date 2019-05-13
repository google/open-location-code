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
  __COMMENT=`clean_body "$2"`
  if [ -z "$TRAVIS_PULL_REQUEST" ]; then
    # We're not even in TravisCI AFAICT.
    return 0
  fi
  if [ "$TRAVIS_PULL_REQUEST" == "false" ]; then
    # We're not processing a pull request.
    return 0
  fi
  __BODY="{\"body\": \"_This is an automated bot comment from the TravisCI tests_  \n$__COMMENT\"}"
  payload_to_github \
      "https://api.github.com/repos/${TRAVIS_REPO_SLUG}/issues/${TRAVIS_PULL_REQUEST}/comments" \
      "$__BODY"
}

# Post a comment to a specific file in a pull request.
# The file path should be the first argument, the body the second. The body will
# also be echoed to stdout.
function post_file_comment {
  __FILE=$1
  __COMMENT=`clean_body "$2"`
  echo "Comment is $__COMMENT"
  if [ -z "$TRAVIS_PULL_REQUEST" ]; then
    # We're not even in TravisCI AFAICT.
    return 0
  fi
  if [ "$TRAVIS_PULL_REQUEST" == "false" ]; then
    # We're not processing a pull request.
    return 0
  fi
  # TRAVIS_PULL_REQUEST_SHA
  env|grep TRAV
  __COMMIT_SHA=`git rev-parse FETCH_HEAD`
  __BODY="{
  \"body\": \"_This is an automated bot comment from the TravisCI tests_  \n$__COMMENT\",
  \"commit_id\": \"$__COMMIT_SHA\",
  \"path\": \"$1\",
  \"position\": 1}"
  payload_to_github \
      "https://api.github.com/repos/${TRAVIS_REPO_SLUG}/pulls/${TRAVIS_PULL_REQUEST}/comments" \
      "$__BODY"
}

# Post a payload to a GitHub API URL.
# The first argument is the URL, the second is the payload.
function payload_to_github {
  __URL=$1
  __PAYLOAD=$2
  if [ -z "$__URL" ]; then
    echo -e "\e[31mNo URL to post to GitHub\e[30m"
    return 0
  fi
  if [ -z "$__PAYLOAD" ]; then
    echo -e "\e[31mNo payload to post to GitHub\e[30m"
    return 0
  fi
  if [ -z "$GITHUB_TOKEN" ]; then
    echo -e "\e[31mNo auth token, cannot send to GitHub\e[30m"
    return 0
  fi
  __LOG=`mktemp`
  __STATUS=`curl -s -o "$__LOG" -w "%{http_code}" \
    -H "Authorization: token ${GITHUB_TOKEN}" -X POST \
    -d "$__PAYLOAD" "$__URL"`
  if [ "$__STATUS" != "200" ]; then
    echo -e "\e[31mFailed sending comment to GitHub (status $__STATUS):\e[30m"
    cat "$__LOG"
    echo "URL was: $__URL"
    echo "Payload was: >>$__PAYLOAD<<"
  fi
}

# Format a string so that it's JSON safe.
function clean_body {
  # Remove literal linefeeds and change them to "  \n".
  # Remove bash colour characters or GitHub's comment JSON parser will complain.
  # Convert new lines into "  \n" so they are formatted correctly in markdown.
  # Convert quotes into backspaced quotes.
  echo "$1" | \
      sed ':a;N;$!ba;s/\n/  \\n/g' | \
      sed -r "s/\x1B\[[0-9]+m//g" | \
      sed -r 's/\"/\\\"/g'
}
