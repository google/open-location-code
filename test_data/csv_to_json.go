// Package main converts test files from CSV to JSON.
// This can be used by e.g. JS tests that cannot read data as CSV.
// Example:
//   go run csv_to_json.go --csv encoding.csv >js/test/encoding.json
package main

import (
	"bufio"
	"encoding/csv"
	"flag"
	"fmt"
	"log"
	"os"
	"strconv"
	"strings"
)

var (
	csvPtr = flag.String("csv", "", "CSV file")
)

func main() {
	flag.Parse()
	if *csvPtr == "" {
		log.Fatal("--csv is required")
	}
	csvFile, err := os.Open(*csvPtr)
	if err != nil {
		log.Fatal(err)
	}
	reader := csv.NewReader(bufio.NewReader(csvFile))
	reader.Comment = '#'
	records, err := reader.ReadAll()
	if err != nil {
		log.Fatal(err)
	}
	var formatted []string
	for i := 0; i < len(records); i++ {
		for j := 0; j < len(records[i]); j++ {
			// Anything that can't be parsed as a float is a string and needs quotes.
			if _, err := strconv.ParseFloat(records[i][j], 64); err != nil {
				records[i][j] = "\"" + records[i][j] + "\""
			}
		}
		formatted = append(formatted, "["+strings.Join(records[i], ",")+"]")
	}
	fmt.Printf("[\n%s\n]\n", strings.Join(formatted, ",\n"))
}
