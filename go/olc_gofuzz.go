//go:build gofuzz
// +build gofuzz

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

package olc

//go:generate go run corpus/gen.go -test-data=../test_data -dest=corpus

// Fuzz usage:
//
//	go get github.com/dvyukov/go-fuzz/...
//
//	go-fuzz-build github.com/google/open-location-code/go && go-fuzz -bin=./olc-fuzz.zip -workdir=/tmp/olc-fuzz
func Fuzz(data []byte) int {
	code := string(data)
	if err := Check(code); err != nil {
		return 0
	}
	area, err := Decode(code)
	if err != nil {
		return 2
	}
	if _, err = Decode(Encode(area.LatLo, area.LngLo, len(code))); err != nil {
		return 2
	}
	if _, err = Decode(Encode(area.LatHi, area.LngHi, len(code))); err != nil {
		return 2
	}

	return 1
}
