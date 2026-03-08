package main

import (
	"crypto/tls"
	"encoding/json"
	"expvar"
	"fmt"
	"io"
	"io/ioutil"
	"log"
	"net/http"
	"os"
	"strings"
	"sync"
	"time"

	rice "github.com/GeertJohan/go.rice"
	"github.com/gorilla/mux"
	gosocketio "github.com/graarh/golang-socketio"
	"github.com/graarh/golang-socketio/transport"
)

var countingServiceURL string
var consulAddr string
var port string
var countingInsecureTLS bool
var serviceIndex int
var serviceLock sync.Mutex

func main() {
	port = getEnvOrDefault("PORT", "80")
	portWithColon := fmt.Sprintf(":%s", port)

	consulAddr = getEnvOrDefault("CONSUL_HTTP_ADDR", "")
	countingServiceURL = getEnvOrDefault("COUNTING_SERVICE_URL", "")
	countingInsecureTLS = strings.EqualFold(getEnvOrDefault("COUNTING_INSECURE_TLS", "false"), "true")

	fmt.Printf("Starting server on http://0.0.0.0:%s\n", port)
	fmt.Println("(Pass as PORT environment variable)")
	if consulAddr != "" {
		fmt.Printf("Using Consul at %s for service discovery\n", consulAddr)
	} else if countingServiceURL != "" {
		fmt.Printf("Using counting service at %s\n", countingServiceURL)
		fmt.Println("(Pass as COUNTING_SERVICE_URL environment variable)")
	} else {
		fmt.Println("Warning: No CONSUL_HTTP_ADDR or COUNTING_SERVICE_URL configured")
	}

	failTrack := new(failureTracker)

	router := mux.NewRouter()
	router.PathPrefix("/socket.io/").Handler(startWebsocket(failTrack))
	router.HandleFunc("/health", HealthHandler)
	router.HandleFunc("/health/api", HealthAPIHandler(failTrack))
	router.Handle("/metrics", expvar.Handler())
	router.PathPrefix("/").Handler(http.FileServer(rice.MustFindBox("assets").HTTPBox()))

	log.Fatal(http.ListenAndServe(portWithColon, router))
}

func getEnvOrDefault(key, fallback string) string {
	if value, ok := os.LookupEnv(key); ok {
		return value
	}
	return fallback
}

// HealthHandler returns a successful status and a message.
// For use by Consul or other processes that need to verify service health.
func HealthHandler(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	fmt.Fprintf(w, "Hello, you've hit %s\n", r.URL.Path)
}

type failureTracker struct {
	lock     sync.RWMutex
	latest   bool // indicates condition of most recent connection attempt
	failures int  // counts the number of consecutive connection failures
}

func (ft *failureTracker) Count(ok bool) {
	ft.lock.Lock()
	defer ft.lock.Unlock()

	if ft.latest = ok; ok {
		ft.failures = 0
	} else {
		ft.failures++
	}
}

func (ft *failureTracker) Status() (bool, int) {
	ft.lock.RLock()
	defer ft.lock.RUnlock()
	return ft.latest, ft.failures
}

// HealthAPIHandler returns the condition of the connectivity between the
// dashboard and the backend API server.
func HealthAPIHandler(ft *failureTracker) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		statusOK, failures := ft.Status()
		if statusOK {
			w.WriteHeader(http.StatusOK)
			_, _ = io.WriteString(w, "ok")
		} else {
			w.WriteHeader(http.StatusServiceUnavailable)
			_, _ = io.WriteString(w, fmt.Sprintf(
				"failures: %d", failures,
			))
		}
	}
}

func startWebsocket(ft *failureTracker) *gosocketio.Server {
	server := gosocketio.NewServer(transport.GetDefaultWebsocketTransport())

	fmt.Println("Starting websocket server...")
	server.On(gosocketio.OnConnection, handleConnectionFunc(ft))
	server.On("send", handleSendFunc(ft))

	return server
}

func handleConnectionFunc(ft *failureTracker) func(c *gosocketio.Channel) {
	return func(c *gosocketio.Channel) {
		fmt.Println("New client connected")
		c.Join("visits")
		handleSendFunc(ft)(c, Count{})
	}
}

func handleSendFunc(ft *failureTracker) func(*gosocketio.Channel, Count) string {
	return func(c *gosocketio.Channel, msg Count) string {
		count, err := getAndParseCount()
		if err != nil {
			count = Count{Count: -1, Message: err.Error(), Hostname: "[Unreachable]"}
			ft.Count(false)
		} else {
			ft.Count(true)
		}
		fmt.Println("Fetched count", count.Count)
		c.Ack("message", count, time.Second*10)
		return "OK"
	}
}

// Count stores a number that is being counted and other data to send to
// websocket clients.
type Count struct {
	Count    int    `json:"count"`
	Message  string `json:"message"`
	Hostname string `json:"hostname"`
}

func getAndParseCount() (Count, error) {
	var url string

	if countingServiceURL != "" {
		url = countingServiceURL
	} else if consulAddr != "" {
		// Discover service from Consul with round-robin
		serviceURL, err := discoverServiceFromConsul()
		if err != nil {
			return Count{}, fmt.Errorf("failed to discover service: %v", err)
		}
		url = serviceURL
	} else {
		return Count{}, fmt.Errorf("no service URL configured")
	}

	// NOTE: We use short timeouts so round robin load balancing
	// of services can be experienced during lab demos.
	tr := &http.Transport{
		IdleConnTimeout: time.Second * 1,
	}
	if strings.HasPrefix(strings.ToLower(url), "https://") && countingInsecureTLS {
		tr.TLSClientConfig = &tls.Config{
			// Demo mode for local/self-signed OpenSSL certificates.
			InsecureSkipVerify: true,
		}
	}

	httpClient := http.Client{
		Timeout:   time.Second * 2,
		Transport: tr,
	}

	req, err := http.NewRequest(http.MethodGet, url, nil)
	if err != nil {
		return Count{}, err
	}

	req.Header.Set("User-Agent", "HashiCorp Training Lab")

	res, getErr := httpClient.Do(req)
	if getErr != nil {
		return Count{}, getErr
	}

	body, readErr := ioutil.ReadAll(res.Body)
	if readErr != nil {
		return Count{}, readErr
	}

	defer res.Body.Close()
	return parseCount(body)
}

func parseCount(body []byte) (Count, error) {
	textBytes := []byte(body)

	count := Count{}
	err := json.Unmarshal(textBytes, &count)
	if err != nil {
		fmt.Println(err)
		return count, err
	}
	return count, err
}

type consulService struct {
	Service struct {
		Address string
		Port    int
	}
}

func discoverServiceFromConsul() (string, error) {
	url := fmt.Sprintf("%s/v1/health/service/counting-service?passing", consulAddr)

	httpClient := http.Client{
		Timeout: time.Second * 2,
	}

	resp, err := httpClient.Get(url)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return "", err
	}

	var services []consulService
	if err := json.Unmarshal(body, &services); err != nil {
		return "", err
	}

	if len(services) == 0 {
		return "", fmt.Errorf("no healthy counting-service instances found")
	}

	// Round-robin load balancing
	serviceLock.Lock()
	index := serviceIndex % len(services)
	serviceIndex++
	serviceLock.Unlock()

	service := services[index].Service
	serviceURL := fmt.Sprintf("http://%s:%d", service.Address, service.Port)
	fmt.Printf("Using counting service: %s\n", serviceURL)
	return serviceURL, nil
}
