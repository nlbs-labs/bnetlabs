package api

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"time"
)

type Client struct {
	baseURL    string
	httpClient *http.Client
}

type HelloRequest struct {
	EphemeralPub string `json:"ephemeral_pub"`
	Timestamp    int64  `json:"timestamp"`
	TokenHash    string `json:"token_hash"`
}

type HelloResponse struct {
	SessionID          string `json:"session_id"`
	ServerEphemeralPub string `json:"server_ephemeral_pub"`
	Challenge          string `json:"challenge"`
	ServerFingerprint  string `json:"server_fingerprint"`
}

type ResponseRequest struct {
	SessionID         string `json:"session_id"`
	ChallengeResponse string `json:"challenge_response"`
	ClientStaticPub   string `json:"client_static_pub"`
	DeviceID          string `json:"device_id"`
	Hostname          string `json:"hostname,omitempty"`
	OS                string `json:"os,omitempty"`
}

type ServerConfirmation struct {
	AssignedIP   string     `json:"assigned_ip"`
	WGServerPub  string     `json:"wg_server_pub"`
	WGEndpoint   string     `json:"wg_endpoint"`
	Peers        []PeerInfo `json:"peers"`
	SessionToken string     `json:"session_token"`
}

type PeerInfo struct {
	PublicKey  string `json:"public_key"`
	AssignedIP string `json:"assigned_ip"`
	Name       string `json:"name"`
}

type ACKRequest struct {
	SessionID string `json:"session_id"`
}

type JoinRequest struct {
	Token string `json:"token"`
}

type JoinResponse struct {
	Message   string `json:"message"`
	ProjectID string `json:"project_id"`
	DeviceID  string `json:"device_id"`
}

type apiResponse struct {
	Data json.RawMessage `json:"data"`
	Err  string          `json:"error,omitempty"`
}

func New(baseURL string) *Client {
	if baseURL == "" {
		baseURL = "https://bnetscale.nlbs.me"
	}
	return &Client{
		baseURL: baseURL,
		httpClient: &http.Client{
			Timeout: 30 * time.Second,
		},
	}
}

func (c *Client) Join(token string) (*JoinResponse, error) {
	req := JoinRequest{Token: token}
	var res JoinResponse
	if err := c.post("/api/v1/join", req, &res); err != nil {
		return nil, err
	}
	return &res, nil
}

func (c *Client) HandshakeHello(req *HelloRequest) (*HelloResponse, error) {
	var res HelloResponse
	if err := c.post("/api/v1/handshake/hello", req, &res); err != nil {
		return nil, err
	}
	return &res, nil
}

func (c *Client) HandshakeResponse(req *ResponseRequest) (*ServerConfirmation, error) {
	var res ServerConfirmation
	if err := c.post("/api/v1/handshake/response", req, &res); err != nil {
		return nil, err
	}
	return &res, nil
}

func (c *Client) HandshakeACK(sessionID string) error {
	req := ACKRequest{SessionID: sessionID}
	return c.post("/api/v1/handshake/ack", req, nil)
}

func (c *Client) post(path string, body any, result any) error {
	data, err := json.Marshal(body)
	if err != nil {
		return fmt.Errorf("marshal request: %w", err)
	}

	req, err := http.NewRequest(http.MethodPost, c.baseURL+path, bytes.NewReader(data))
	if err != nil {
		return fmt.Errorf("create request: %w", err)
	}
	req.Header.Set("Content-Type", "application/json")

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return fmt.Errorf("http request: %w", err)
	}
	defer resp.Body.Close()

	respData, err := io.ReadAll(resp.Body)
	if err != nil {
		return fmt.Errorf("read response: %w", err)
	}

	var wrapper apiResponse
	if err := json.Unmarshal(respData, &wrapper); err != nil {
		return fmt.Errorf("parse response: %w", err)
	}

	if resp.StatusCode >= 400 {
		errMsg := wrapper.Err
		if errMsg == "" {
			errMsg = fmt.Sprintf("http %d", resp.StatusCode)
		}
		return fmt.Errorf("server error: %s", errMsg)
	}

	if result != nil && len(wrapper.Data) > 0 {
		if err := json.Unmarshal(wrapper.Data, result); err != nil {
			return fmt.Errorf("unmarshal result: %w", err)
		}
	}

	return nil
}
