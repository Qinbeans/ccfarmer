package websockets

import (
	"encoding/json"
	"log"
	"net/http"
	"time"

	"github.com/google/uuid"
	"github.com/gorilla/websocket"
)

const (
	ExpiredTime = 60 * 60 * 24
)

type Farm struct {
	Id        string
	Conn      *websocket.Conn
	Map       map[string]string
	CreatedAt int64
}

type WebsocketHandler struct {
	Upgrader websocket.Upgrader
	Clients  map[string]*Farm
}

func NewServer() *WebsocketHandler {
	return &WebsocketHandler{
		Upgrader: websocket.Upgrader{},
		Clients:  make(map[string]*Farm),
	}
}

// middleware to free dangling connections, ie client's that don't activate the websocket after connecting
func (ws *WebsocketHandler) Middleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		for id, client := range ws.Clients {
			if time.Now().Unix()-client.CreatedAt > ExpiredTime {
				log.Printf("deleting client %s", id)
				delete(ws.Clients, id)
			}
		}

		next.ServeHTTP(w, r)
	})
}

func (ws *WebsocketHandler) Close() {
	for id, client := range ws.Clients {
		client.Conn.Close()
		delete(ws.Clients, id)
	}
}

func (ws *WebsocketHandler) CloseClient(id string) {
	if client, ok := ws.Clients[id]; ok {
		client.Conn.Close()
		delete(ws.Clients, id)
	}
}

func (ws *WebsocketHandler) Connect(w http.ResponseWriter, r *http.Request) {
	id, _ := uuid.NewUUID()

	// unix epoch time in seconds
	createdAt := time.Now().Unix()

	ws.Clients[id.String()] = &Farm{
		Id:        id.String(),
		Conn:      nil,
		Map:       make(map[string]string),
		CreatedAt: createdAt,
	}

	// write the id to the response
	jsonMsg, err := json.Marshal(map[string]string{"id": id.String()})
	if err != nil {
		http.Error(w, "could not marshal json", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.Write(jsonMsg)
}

func (ws *WebsocketHandler) WsEndpoint(w http.ResponseWriter, r *http.Request) {
	id := r.URL.Query().Get("id")

	if id == "" {
		http.Error(w, "id is required", http.StatusBadRequest)
		return
	}

	if _, ok := ws.Clients[id]; !ok {
		http.Error(w, "client not found", http.StatusNotFound)
		return
	}

	conn, err := ws.Upgrader.Upgrade(w, r, nil)
	if err != nil {
		http.Error(w, "could not open websocket connection", http.StatusBadRequest)
		return
	}

	ws.Clients[id].Conn = conn

	go ws.Handler(id)
}

// WebSocket handler
func (ws *WebsocketHandler) Handler(id string) {
	defer ws.CloseClient(id)
	// send a hello message to the client
	err := ws.Clients[id].Conn.WriteMessage(websocket.TextMessage, []byte("hello"))
	if err != nil {
		log.Printf("error: %v", err)
		delete(ws.Clients, id)
		return
	}
	for {
		// Read message from browser
		_, msg, err := ws.Clients[id].Conn.ReadMessage()
		if err != nil {
			log.Printf("error: %v", err)
			delete(ws.Clients, id)
			return
		}

		// Print the message to the console
		println(string(msg))
	}
}
