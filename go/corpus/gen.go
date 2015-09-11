// Copyright 2015 Tamás Gulácsi. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the 'License');
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an 'AS IS' BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// This little program generates 00%d.code.txt corpus for go-fuzz-build,
// into the given directory.
package main

import (
	"bytes"
	"flag"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"path/filepath"
	"strings"
)

func main() {
	flagDir := flag.String("dest", ".", "destination directory")
	flagTestData := flag.String("test-data", filepath.Join("..", "..", "test_data"), "the js test_data with the csv files for tests")
	flag.Parse()

	if err := extractCorpus(*flagDir, *flagTestData); err != nil {
		log.Fatal(err)
	}
}

func extractCorpus(dir, src string) error {
	fis, err := ioutil.ReadDir(src)
	if err != nil {
		log.Printf("read test_data from %s: %v", src, err)
		return err
	}
	_ = os.MkdirAll(dir, 0755)
	n := 0
	for _, fi := range fis {
		if !strings.HasSuffix(fi.Name(), ".csv") {
			continue
		}
		fn := filepath.Join(src, fi.Name())
		data, err := ioutil.ReadFile(fn)
		if err != nil {
			log.Printf("read csv %s: %v", fn, err)
			continue
		}
		for _, row := range bytes.Split(data, []byte{'\n'}) {
			if i := bytes.IndexByte(row, '#'); i >= 0 {
				row = row[:i]
			}
			// assume that the first field is the code
			if i := bytes.IndexByte(row, ','); i >= 0 {
				fn := filepath.Join(dir, fmt.Sprintf("%003d.code.txt", n))
				if err := ioutil.WriteFile(fn, row[:i], 0644); err != nil {
					log.Printf("Write %s: %v", fn, err)
					continue
				}
				n++
			}
		}
	}
	return nil
}
