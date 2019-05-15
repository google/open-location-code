// Provides bash functions to send comments to GitHub pull requests.
//
// This expects the environment variable GITHUB_TOKEN must exist with an authorisation token.
//
// You can add a comment to the PR conversation:
//   go run github_comments.go --pr 338 --comment "...."
// Or you can add a comment to a file within the PR (the file path must be relative to the repo root):
//   go run github_comments.go --pr 338 --comment "...." --file dart/lib/src/open_location_code.dart --commit 2592c2a78d5be48508dde390e51f585d15182fca
//
// For information on the GitHub API, see: https://developer.github.com/v3/

package main

import (
	"bytes"
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"regexp"
	"strings"
	"time"
)

const (
	// Review comments are comments in a pull request associated with files.
	reviewCommentsUrl = "https://api.github.com/repos/%s/pulls/%s/comments"
	// Issue comments are comments in a pull request (or issue) conversation.
	issueCommentsUrl = "https://api.github.com/repos/%s/issues/%s/comments"
	// Issue comment edit URL.
	issueCommentEditUrl = "https://api.github.com/repos/%s/issues/comments/%d"
	// Name of environment variable with GitHub authorisation token.
	githubToken = "GITHUB_TOKEN"
	// Comment to use when a file comment is added into the conversation.
	failedFileComment = "_There are issues with the file `%s` but it does not appear to be modified by this pull request.<br>" +
		"If you can, please fix them, or consider fixing them in another pull request. You could also report them in a new issue._<br>%s"
)

// GitHubCommentRequest defines the POST data to add a comment to a pull review.
// To add to the conversation, just Body need be specified.
// If CommitID and Path are specified, the comment will be added to the file.
type GitHubCommentRequest struct {
	Body      string `json:"body,omitempty"`
	CommitID  string `json:"commit_id,omitempty"`
	Path      string `json:"path,omitempty"`
	Position  int    `json:"position,omitempty"`
	InReplyTo int    `json:"in_reply_to,omitempty"`
}

// GitHubError defines error data returned when a request fails..
type GitHubError struct {
	Resource string `json:"resource"`
	Code     string `json:"code"`
	Field    string `json:"field"`
}

// GitHubCommentResponse is the response returned from trying to add a comment.
type GitHubCommentResponse struct {
	Message string        `json:"message"`
	Errors  []GitHubError `json:"errors"`
	Path    string        `json:"path"`
	Body    string        `json:"body"`
	NodeID  string        `json:"node_id"`
	HtmlUrl string        `json:"html_url"`
}

// GitHubComment is a single comment on a pull request.
type GitHubComment struct {
	ID                  int
	PullRequestReviewID int    `json:"pull_request_review_id"`
	InReplyTo           int    `json:"in_reply_to_id"`
	Path                string `json:"path"`
	Body                string `json:"body"`
	UpdatedAt           string `json:"updated_at"`
	NodeID              string `json:"node_id"`
	HtmlUrl             string `json:"html_url"`
}

// main parses the arguments and adds the comment.
func main() {
	repo := flag.String("repo", "google/open-location-code", "Repository path")
	pr := flag.String("pr", "", "Pull request number")
	commit := flag.String("commit", "", "Commit ID SHA")
	comment := flag.String("comment", "", "Comment to add to the pull request")
	file := flag.String("file", "", "Add comment to file instead of conversation (relative path to file)")
	position := flag.Int("position", 1, "Lines from the first @@ hunk header to add the comment")
	prefix := flag.String("prefix", "", "Prefix to add to the comment")
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
	// Post the comment.
	if err := addComment(*repo, *pr, *prefix+*comment, *commit, *file, *position); err != nil {
		log.Printf("Posting comment failed: %v", err)
	}
}

// addComment adds a new comment to the pull request.
// It works out whether the comment is added as a review comment to a file, or
// to the pull request conversation, and either replies to or modifies existing
// comments to avoid duplicates.
func addComment(repo, pr, comment, commit, file string, position int) error {
	var err error
	var existingc []GitHubComment
	// Fetch existing comments.
	if file == "" {
		log.Printf("Fetching issue comments")
		existingc, err = getIssueComments(repo, pr)
	} else {
		log.Printf("Fetching review comments")
		existingc, err = getReviewComments(repo, pr)
	}
	if err != nil {
		return err
	}
	// If the comment has <pre>, replace it with \n<pre> so that "---" strings in the preformatted section don't turn everything into a header.
	body := strings.Replace(comment, "<pre>", "\n<pre>", -1)
	// Does it already exist?
	for _, c := range existingc {
		if c.Path == file && commentMatch(c.Body, body) && c.InReplyTo == 0 {
			if file == "" {
				// Add the timestamp to the comment.
				t := time.Now()
				if err := updateIssueComment(repo, c.ID, c.Body+"<br>Ping! (Issue remains on "+t.UTC().Format(time.UnixDate)+")"); err != nil {
					log.Printf("Updating issue comment failed: %v", err)
				}
			} else {
				if err := replyToReviewComment(repo, pr, c.ID, "Ping!"); err != nil {
					log.Printf("Updating review comment failed: %v", err)
				}
			}
			return nil
		}
	}
	// Post a new comment.
	ghc := GitHubCommentRequest{Body: body, CommitID: commit, Path: file, Position: position}
	url := fmt.Sprintf(issueCommentsUrl, repo, pr)
	// If both file and commit have been specified, we post a review comment.
	if file != "" && commit != "" {
		url = fmt.Sprintf(reviewCommentsUrl, repo, pr)
	}
	resp, err := makeCommentRequest(url, ghc)
	// If we got an error, and had a file and commit, retry without the file and commit ID.
	// (If the file is not changed by the pull request we cannot comment on it.)
	if err != nil && file != "" && commit != "" {
		err = addComment(repo, pr, fmt.Sprintf(failedFileComment, file, comment), "", "", 0)
		return nil
	}
	if err == nil {
		log.Printf("Posted comment: %s", resp.HtmlUrl)
		return nil
	}
	return err
}

// getReviewComments gets the comments from the pull request (or issue) conversation.
func getReviewComments(repo, pr string) ([]GitHubComment, error) {
	url := fmt.Sprintf(reviewCommentsUrl, repo, pr)
	return getComments(url)
}

// getIssueComments gets the comments from the pull request (or issue) conversation.
func getIssueComments(repo, pr string) ([]GitHubComment, error) {
	url := fmt.Sprintf(issueCommentsUrl, repo, pr)
	return getComments(url)
}

// updateIssueComment updates an existing conversation comment.
func updateIssueComment(repo string, id int, comment string) error {
	ghc := GitHubCommentRequest{Body: comment}
	url := fmt.Sprintf(issueCommentEditUrl, repo, id)
	resp, err := makeCommentRequest(url, ghc)
	if err == nil {
		log.Printf("Updated existing comment: %s", resp.HtmlUrl)
	}
	return err
}

// replyToReviewComment replies to an existing review comment.
func replyToReviewComment(repo, pr string, cid int, comment string) error {
	ghc := GitHubCommentRequest{Body: comment, InReplyTo: cid}
	url := fmt.Sprintf(reviewCommentsUrl, repo, pr)
	resp, err := makeCommentRequest(url, ghc)
	if err == nil {
		log.Printf("Replied to existing review comment: %s", resp.HtmlUrl)
	}
	return err
}

// makeCommentRequest makes a POST request to the url and sends the GitHub request.
// It relies on the environment variable GITHUB_TOKEN for authentication.
func makeCommentRequest(url string, ghc GitHubCommentRequest) (*GitHubCommentResponse, error) {
	// Encode the request.
	b := new(bytes.Buffer)
	if err := json.NewEncoder(b).Encode(ghc); err != nil {
		return nil, err
	}
	// Send request.
	bytes, err := callGitHubAPI("POST", url, b)
	if err != nil {
		return nil, err
	}
	var resp GitHubCommentResponse
	if err := json.Unmarshal(bytes, &resp); err != nil {
		log.Printf("Error decoding JSON response: %v\n%v", err, string(bytes))
		return nil, err
	}
	return &resp, nil
}

// getComments fetches the comments using the passed URL.
func getComments(url string) ([]GitHubComment, error) {
	var resp []GitHubComment
	bytes, err := callGitHubAPI("GET", url, nil)
	if err != nil {
		return resp, err
	}
	if err := json.Unmarshal(bytes, &resp); err != nil {
		log.Printf("Error decoding JSON response: %v\n%v", err, string(bytes))
		return resp, err
	}
	return resp, nil
}

// callGitHubAPI calls the passed URL and returns the byte response, setting headers appropriately.
func callGitHubAPI(method, url string, body io.Reader) ([]byte, error) {
	// Get the GitHub auth token from environment variables.
	token := os.Getenv(githubToken)
	if token == "" {
		return []byte(""), fmt.Errorf("No %s environment variable", githubToken)
	}
	// Create request.
	req, err := http.NewRequest(method, url, body)
	if err != nil {
		return []byte(""), err
	}
	// Add require headers.
	req.Header.Add("Accept", "application/vnd.github.v3+json")
	req.Header.Add("Content-Type", "application/json; charset=utf-8")
	req.Header.Add("Authorization", "token "+token)
	r, err := http.DefaultClient.Do(req)
	if err != nil {
		return []byte(""), err
	}
	if r.Status != "201 Created" && r.Status != "200 OK" {
		return []byte(""), fmt.Errorf("Request failed, response code: %s", r.Status)
	}
	buf := new(bytes.Buffer)
	buf.ReadFrom(r.Body)
	return buf.Bytes(), nil
}

// commentMatch returns true if string b is within a, after stripping tags and everything other than letters and numbers.
func commentMatch(a, b string) bool {
	re := regexp.MustCompile("\n|</?[a-z]*>|[^a-zA-Z0-9]")
	a = re.ReplaceAllString(a, "")
	b = re.ReplaceAllString(b, "")
	return strings.Contains(a, b)
}
