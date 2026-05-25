package cmd

import (
	"fmt"
	"io"
	"os"
	"os/exec"
	"strings"

	"git.nafi-labs.tech/Labs/bnetscale/client/internal/config"
)

func Up(args []string) {
	ensureRoot()
	if !config.ConfigExists() {
		fmt.Fprintln(os.Stderr, "Not configured. Run 'bnetscale join <token>' first.")
		os.Exit(1)
	}

	cfg, err := config.Load()
	if err != nil {
		fmt.Fprintf(os.Stderr, "Failed to load config: %v\n", err)
		os.Exit(1)
	}

	ifaceName := "bnetscale0"

	setup := [][]string{
		{"ip", "link", "add", ifaceName, "type", "wireguard"},
		{"ip", "addr", "add", "dev", ifaceName, cfg.AssignedIP},
		{"ip", "link", "set", ifaceName, "up"},
	}
	for _, a := range setup {
		exec.Command(a[0], a[1:]...).Run()
	}

	setKey := exec.Command("wg", "set", ifaceName, "private-key", "/dev/stdin")
	stdin, _ := setKey.StdinPipe()
	go func() {
		defer stdin.Close()
		io.WriteString(stdin, cfg.PrivateKey+"\n")
	}()
	setKey.Run()

	wgSet := []string{"set", ifaceName}
	wgSet = append(wgSet, "peer", cfg.WGServerPub, "endpoint", cfg.WGEndpoint, "allowed-ips", "0.0.0.0/0", "persistent-keepalive", "25")
	exec.Command("wg", wgSet...).Run()

	for _, peer := range cfg.Peers {
		peerIP := strings.Split(peer.AssignedIP, "/")[0]
		p2pArgs := []string{"set", ifaceName, "peer", peer.PublicKey, "allowed-ips", peerIP, "persistent-keepalive", "25"}
		if err := exec.Command("wg", p2pArgs...).Run(); err != nil {
			fmt.Fprintf(os.Stderr, "P2P peer %s warning: %v\n", peer.Name, err)
		}
	}

	fmt.Printf("Tunnel up: %s on %s (%d peers)\n", ifaceName, cfg.AssignedIP, len(cfg.Peers))
	_ = args
}
