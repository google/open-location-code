// Provides bash functions to send comments to GitHub pull requests.
//
// This expects the environment variable GITHUB_TOKEN must exist with an authorisation token.
//
// You can add a comment to the PR conversation:
//   go run github_comments.go --pr 338 --comment "...."
// Or you can add a comment to a file within the PR (the file path must be relative to the repo root):
//   go run github_comments.go --pr 338 --comment "...." --file dart/lib/src/open_location_code.dart --commit 2592c2a78d5be48508dde390e51f585d15182fca

package main

import (
	"bytes"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"log"
	"net/http"
	"os"
	"regexp"
	"strings"
)

const (
	stdPrefix        = "_This is an automated bot comment from the TravisCI tests_<br>"
	fetchCommentsUrl = "https://api.github.com/repos/%s/pulls/%s/comments"
	commentOnPRUrl   = "https://api.github.com/repos/%s/issues/%s/comments"
	commentOnFileUrl = "https://api.github.com/repos/%s/pulls/%s/comments"
)

var (
	repo     = flag.String("repo", "google/open-location-code", "Repository path")
	pr       = flag.String("pr", "", "Pull request number")
	commit   = flag.String("commit", "", "Commit ID SHA")
	comment  = flag.String("comment", "", "Comment to add to the pull request")
	file     = flag.String("file", "", "Add comment to file instead of conversation (relative path to file)")
	position = flag.Int("position", 1, "Lines from the first @@ hunk header to add the comment")
	prefix   = flag.String("prefix", stdPrefix, "Prefix to add to the comment")
  // If allowDupes is true, the new comment won't be compared against existing comments.
  // Note that the GitHub API does not return the comment state, so we cannot tell if comments are resolved.
  // If allowDupes is false, and the new comment matches a resolved one, it will not be added to the PR!
  allowDupes = flag.Bool("dupes", false, "Allow duplicate comments")
)

// GitHubReviewCommentRequest defines the POST data to add a comment to a pull review.
// To add to the conversation, just Body need be specified.
// If CommitID and Path are specified, the comment will be added to the file.
type GitHubReviewCommentRequest struct {
	Body     string `json:"body,omitifempty"`
	CommitID string `json:"commit_id,omitifempty"`
	Path     string `json:"path,omitifempty"`
	Position int    `json:"position,omitifempty"`
}

// GitHubError defines error data returned when a request fails..
type GitHubError struct {
	Resource string `json:"resource"`
	Code     string `json:"code"`
	Field    string `json:"field"`
}

// GitHubReviewCommentResponse is the response returned from trying to add a comment.
type GitHubReviewCommentResponse struct {
	Message string        `json:"message"`
	Errors  []GitHubError `json:"errors"`
	Path    string        `json:"path"`
	Body    string        `json:"body"`
	HtmlUrl string        `json:"html_url"`
}

// GitHubReviewComment is a single comment on a pull request.
type GitHubReviewComment struct {
	ID                  int
	PullRequestReviewID int    `json:"pull_request_review_id"`
	InReplyTo           int    `json:"in_reply_to_id"`
	Path                string `json:"path"`
	Body                string `json:"body"`
	UpdatedAt           string `json:"updated_at"`
	NodeID              string `json:"node_id"`
	HtmlUrl             string `json:"html_url"`
}

// Fetch the comments for the pull request.
func getComments(repo, pr string) ([]GitHubReviewComment, error) {
	var resp []GitHubReviewComment
	// Get the GitHub auth token from environment variables. Strictly speaking this may not be needed but helps to avoid rate limiting.
	token := os.Getenv("GITHUB_TOKEN")
	if token == "" {
		return resp, errors.New("Cannot send comment - no GITHUB_TOKEN environment variable")
	}
	url := fmt.Sprintf(fetchCommentsUrl, repo, pr)
  // Send request.
	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		return resp, err
	}
	req.Header.Add("Content-Type", "application/json; charset=utf-8")
	req.Header.Add("Authorization", "token "+token)
	r, err := http.DefaultClient.Do(req)
	if err != nil {
		return resp, err
	}
  buf := new(bytes.Buffer)
  buf.ReadFrom(r.Body)
	if err := json.Unmarshal(buf.Bytes(), &resp); err != nil {
    log.Printf("Error decoding JSON response: %v\n%v", err, buf.String())
		return resp, err
	}
	if r.Status != "200 OK" {
		return resp, errors.New("Request failed")
	}
	return resp, nil
}

// Send the comment to the pull request.
// If the file is specified, the comment will be attached to the file (as long
// as the commit ID is also specified), otherwise it will be put into the PR
// conversation.
func sendComment(repo, pr, comment, commit, file string, position int) error {
	// Get the GitHub auth token from environment variables.
	token := os.Getenv("GITHUB_TOKEN")
	if token == "" {
		return errors.New("Cannot send comment - no GITHUB_TOKEN environment variable")
	}
  // If the comment has <pre>, replace it with \n<pre> so that "---" strings in the preformatted section don't turn everything into a header.
  comment = strings.Replace(comment, "<pre>", "\n<pre>", -1)
  ghc := GitHubReviewCommentRequest{Body: comment}
	url := fmt.Sprintf(commentOnPRUrl, repo, pr)
	// If both file and commit have been specified, we can post the comment to a file.
	if file != "" && commit != "" {
		ghc.CommitID = commit
		ghc.Path = file
		ghc.Position = position
		url = fmt.Sprintf(commentOnFileUrl, repo, pr)
		log.Print("Posting comment to file within pull request...")
	} else {
		log.Print("Posting comment to pull request...")
	}
	// Encode the request.
	b := new(bytes.Buffer)
	if err := json.NewEncoder(b).Encode(ghc); err != nil {
		return err
	}
	// Send request.
	req, err := http.NewRequest("POST", url, b)
	if err != nil {
		return err
	}
	req.Header.Add("Content-Type", "application/json; charset=utf-8")
	req.Header.Add("Authorization", "token "+token)
	r, err := http.DefaultClient.Do(req)
	if err != nil {
		return err
	}
	// Decode the response.
  buf := new(bytes.Buffer)
  buf.ReadFrom(r.Body)
	var resp GitHubReviewCommentResponse
	if err := json.Unmarshal(buf.Bytes(), &resp); err != nil {
    log.Printf("Error decoding JSON response: %v\n%v", err, buf.String())
    return err
  }
	if r.Status == "201 Created" {
		log.Printf("Comment added: %s", resp.HtmlUrl)
		return nil
	}
	return errors.New(resp.Message)
}

// True if string b is within a. Strips tags and line feeds.
func match(a, b string) bool {
	re := regexp.MustCompile("\n|</?[a-z]*>|[^a-zA-Z0-9]")
	a = re.ReplaceAllString(a, "")
	b = re.ReplaceAllString(b, "")
	return strings.Contains(a, b)
}

func main() {
	flag.Parse()
  if *pr == "false" {
    // Passed when TravisCI is not within a pull request build, so bail.
    return
  }
	if *pr == "" || *repo == "" {
		log.Print("PR or repo could not be determined")
    return
	}
	if *comment == "" {
		log.Print("No comment specified")
    return
	}
	if (*file == "") != (*commit == "") {
		log.Print("If either of --file and --commit are specified, both must be specified")
    return
	}

  if !*allowDupes {
    // Fetch the existing comments on the PR.
    comments, err := getComments(*repo, *pr)
    if err != nil {
      log.Fatalf("Failed to fetch comments: %v\n", err)
    }
    // Do we already have this comment? We send HTML or literal "\n"s, but we get back markdown (on the whole).
    for _, c := range comments {
      if c.Path == *file && match(c.Body, *comment) && c.InReplyTo == 0 {
        log.Printf("Skipping - PR already contains comment: %s", c.HtmlUrl)
        return
      }
    }
  }
	// Post the comment.
	if err := sendComment(*repo, *pr, *prefix+*comment, *commit, *file, *position); err != nil {
		log.Printf("Posting comment failed: %v", err)
	}
}
