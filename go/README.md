[![GoDoc](https://godoc.org/github.com/google/open-location-code/go?status.svg)](http://godoc.org/github.com/google/open-location-code/go)

# Install

	go get github.com/google/open-location-code/go

# Test with Go-Fuzz

    go get github.com/dvyukov/go-fuzz/...

	go generate github.com/google/open-location-code/go

    go-fuzz-build github.com/google/open-location-code/go
	go-fuzz -bin=./olc-fuzz.zip -workdir=/tmp/olc-fuzz

