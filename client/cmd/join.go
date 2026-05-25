package cmd

import (
	"fmt"
	"os"
	"strings"

	"git.nafi-labs.tech/Labs/bnetscale/client/internal/api"
	"git.nafi-labs.tech/Labs/bnetscale/client/internal/config"
	"git.nafi-labs.tech/Labs/bnetscale/client/internal/handshake"
)

func Join(args []string) {
	ensureRoot()
	if len(args) < 1 {
		fmt.Fprintln(os.Stderr, "Usage: bnetscale join <token> [--server <url>]")
		os.Exit(1)
	}

	token := args[0]
	serverURL := "https://bnetscale.nlbs.me"

	for i := 1; i < len(args); i++ {
		if args[i] == "--server" && i+1 < len(args) {
			serverURL = args[i+1]
			i++
		}
	}

	client := api.New(serverURL)

	joinResp, err := client.Join(token)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Failed to join project: %v\n", err)
		if strings.Contains(err.Error(), "connection refused") || strings.Contains(err.Error(), "no such host") {
			fmt.Fprintln(os.Stderr, "")
			fmt.Fprintln(os.Stderr, "  Hint: Use --server to specify the server URL, e.g.:")
			fmt.Fprintln(os.Stderr, "    bnetscale join <token> --server https://bnetscale.nlbs.me")
		}
		os.Exit(1)
	}

	fmt.Printf("Joined project %s as device %s\n", joinResp.ProjectID, joinResp.DeviceID)
	fmt.Println("Starting handshake...")

	cryptoDir, err := config.Dir()
	if err != nil {
		fmt.Fprintf(os.Stderr, "Config directory error: %v\n", err)
		os.Exit(1)
	}
	fmt.Printf("Config directory: %s\n", cryptoDir)

	deviceID := joinResp.DeviceID

	result, err := handshake.Execute(client, serverURL, deviceID, token)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Handshake failed: %v\n", err)
		os.Exit(1)
	}

	p2pPeers := make([]config.Peer, len(result.Peers))
	for i, p := range result.Peers {
		p2pPeers[i] = config.Peer{
			PublicKey:  p.PublicKey,
			AssignedIP: p.AssignedIP,
			Name:       p.Name,
		}
	}

	cfg := &config.Config{
		ServerURL:    serverURL,
		ProjectID:    joinResp.ProjectID,
		DeviceID:     result.DeviceID,
		AssignedIP:   result.AssignedIP,
		PrivateKey:   result.PrivateKey,
		WGServerPub:  result.WGServerPub,
		WGEndpoint:   result.WGEndpoint,
		SessionToken: result.SessionToken,
		Peers:        p2pPeers,
	}

	if err := config.Save(cfg); err != nil {
		fmt.Fprintf(os.Stderr, "Failed to save config: %v\n", err)
		os.Exit(1)
	}

	fmt.Printf("Device registered: %s\n", result.AssignedIP)
	fmt.Println("Run 'bnetscale up' to bring the tunnel up.")
}
