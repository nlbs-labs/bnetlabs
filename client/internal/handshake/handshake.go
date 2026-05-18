package handshake

import (
	"crypto/hmac"
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"encoding/hex"
	"fmt"
	"io"
	"time"

	"git.nafi-labs.tech/Labs/bnetscale/client/internal/api"
	"golang.org/x/crypto/curve25519"
	"golang.org/x/crypto/hkdf"
)

const keySize = 32

type PeerInfo struct {
	PublicKey  string `json:"public_key"`
	AssignedIP string `json:"assigned_ip"`
	Name       string `json:"name"`
}

type Result struct {
	DeviceID     string
	AssignedIP   string
	WGServerPub  string
	WGEndpoint   string
	Peers        []PeerInfo
	SessionToken string
	PrivateKey   string
	PublicKey    string
}

func Execute(client *api.Client, serverURL, deviceID, token string) (*Result, error) {
	priv, pub, err := generateKeyPair()
	if err != nil {
		return nil, fmt.Errorf("generate keypair: %w", err)
	}

	tokenHash := sha256Hex([]byte(token))

	helloResp, err := client.HandshakeHello(&api.HelloRequest{
		EphemeralPub: hex.EncodeToString(pub),
		Timestamp:    time.Now().Unix(),
		TokenHash:    tokenHash,
	})
	if err != nil {
		return nil, fmt.Errorf("handshake hello: %w", err)
	}

	serverEphemeralPub, err := hex.DecodeString(helloResp.ServerEphemeralPub)
	if err != nil {
		return nil, fmt.Errorf("decode server ephemeral: %w", err)
	}

	challenge, err := hex.DecodeString(helloResp.Challenge)
	if err != nil {
		return nil, fmt.Errorf("decode challenge: %w", err)
	}

	shared, err := curve25519.X25519(priv, serverEphemeralPub)
	if err != nil {
		return nil, fmt.Errorf("ecdh: %w", err)
	}

	sessionKey := deriveSessionKey(shared)

	mac := hmac.New(sha256.New, sessionKey)
	mac.Write(challenge)
	challengeResponse := mac.Sum(nil)

	confirm, err := client.HandshakeResponse(&api.ResponseRequest{
		SessionID:         helloResp.SessionID,
		ChallengeResponse: hex.EncodeToString(challengeResponse),
		ClientStaticPub:   hex.EncodeToString(pub),
		DeviceID:          deviceID,
	})
	if err != nil {
		return nil, fmt.Errorf("handshake response: %w", err)
	}

	if err := client.HandshakeACK(helloResp.SessionID); err != nil {
		return nil, fmt.Errorf("handshake ack: %w", err)
	}

	peers := make([]PeerInfo, len(confirm.Peers))
	for i, p := range confirm.Peers {
		peers[i] = PeerInfo{
			PublicKey:  p.PublicKey,
			AssignedIP: p.AssignedIP,
			Name:       p.Name,
		}
	}

	return &Result{
		DeviceID:     deviceID,
		AssignedIP:   confirm.AssignedIP,
		WGServerPub:  confirm.WGServerPub,
		WGEndpoint:   confirm.WGEndpoint,
		Peers:        peers,
		SessionToken: confirm.SessionToken,
		PrivateKey:   base64.StdEncoding.EncodeToString(priv),
		PublicKey:    base64.StdEncoding.EncodeToString(pub),
	}, nil
}

func generateKeyPair() (private, public []byte, err error) {
	private = make([]byte, keySize)
	if _, err := rand.Read(private); err != nil {
		return nil, nil, err
	}
	private[0] &= 248
	private[31] &= 127
	private[31] |= 64

	public, err = curve25519.X25519(private, curve25519.Basepoint)
	if err != nil {
		return nil, nil, err
	}
	return private, public, nil
}

func deriveSessionKey(sharedSecret []byte) []byte {
	h := hkdf.New(sha256.New, sharedSecret, nil, []byte("bnetscale-v1"))
	key := make([]byte, keySize)
	if _, err := io.ReadFull(h, key); err != nil {
		return nil
	}
	return key
}

func sha256Hex(data []byte) string {
	h := sha256.Sum256(data)
	return hex.EncodeToString(h[:])
}
