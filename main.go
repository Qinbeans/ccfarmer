package main

import (
	"log"
	"net/http"

	"github.com/Qinbeans/ccfarmer/websockets"
	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
)

func main() {
	address := "0.0.0.0"
	port := "8091"
	r := chi.NewRouter()

	ws := websockets.NewServer()
	defer ws.Close()

	r.Use(ws.Middleware)
	r.Use(middleware.Logger)
	r.Post("/api/connect", ws.Connect)
	r.Get("/api/ws", ws.WsEndpoint)

	log.Printf("Server is running on %s:%s", address, port)
	http.ListenAndServe(address+":"+port, r)
}
