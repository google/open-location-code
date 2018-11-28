// Package main benchmarks the encoding and decoding functions.
// It times a large number of encoding and decoding operations. You can use the
// results to identify the impact of code changes on performance.
package main

import (
	"fmt"
	"math/rand"
	"time"

	olc "github.com/google/open-location-code/go"
)

const (
	// bmsize defines the number of encoding and decoding operations to test.
	bmsize int = 1e7
	// codelen defines the number of digits to encode coordinates into.
	codelen = 16
)

func main() {
	// Build the random lat/lngs
	r := rand.New(rand.NewSource(time.Now().UnixNano()))
	var lat [bmsize]float64
	var lng [bmsize]float64
	var codes [bmsize]string
	fmt.Println("Generating random lat/lngs")
	for i := 0; i < bmsize; i++ {
		lat[i] = r.Float64()*180-90
		lng[i] = r.Float64()*360-180
	}
	fmt.Println("Starting benchmark")
	es := time.Now()
	for i := 0; i < bmsize; i++ {
		codes[i] = olc.Encode(lat[i], lng[i], codelen)
	}
	ds := time.Now()
	for i := 0; i < bmsize; i++ {
		olc.Decode(codes[i])
	}
	end := time.Now()
	fmt.Printf("Total elapsed time, %d operations: %f seconds\n", bmsize, end.Sub(es).Seconds())
	fmt.Printf("Encoding lat/lngs: %.0f op/sec\n", float64(bmsize)/ds.Sub(es).Seconds())
	fmt.Printf("Decoding codes: %.0f op/sec\n", float64(bmsize)/end.Sub(ds).Seconds())
}
