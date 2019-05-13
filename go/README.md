[![GoDoc](https://godoc.org/github.com/google/open-location-code/go?status.svg)](http://godoc.org/github.com/google/open-location-code/go)

# Formatting

Go files must be formatted with [gofmt](https://golang.org/cmd/gofmt/), and the
tests will check that this is the case. If the files are not correctly
formatted, the tests will fail.

You can format your files by running:

	gofmt -w -s .

# Testing

Run the unit tests from within the `go` directory with:

```
go test . -v
```

To also run the benchmark tests, run:

```
go test -bench=. . -v
```

## Test with Go-Fuzz

    go get github.com/dvyukov/go-fuzz/...

	go generate github.com/google/open-location-code/go

    go-fuzz-build github.com/google/open-location-code/go
	go-fuzz -bin=./olc-fuzz.zip -workdir=/tmp/olc-fuzz

# Install

	go get github.com/google/open-location-code/go

