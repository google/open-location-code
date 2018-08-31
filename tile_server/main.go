// main starts the server.
package main

import (
	"flag"
	"fmt"
	"net/http"

	"./gridserver"
)

var (
	port = flag.Int("port", 8080, "Port to run the server on")
)

func init() {
	flag.Parse()
}

func main() {
	gridserver.Init()
	http.HandleFunc("/", gridserver.Handler)
	if err := http.ListenAndServe(fmt.Sprintf(":%v", *port), nil); err != nil {
		panic(err)
	}
}
