package cmd

import (
	"fmt"
	"os"
	"os/exec"
	"strings"

	"git.nafi-labs.tech/Labs/bnetscale/client/internal/config"
)

func Status(args []string) {
	ensureRoot()
	if !config.ConfigExists() {
		fmt.Println("Status: Not configured")
		return
	}

	cfg, err := config.Load()
	if err != nil {
		fmt.Fprintf(os.Stderr, "Config error: %v\n", err)
		os.Exit(1)
	}

	out, _ := exec.Command("wg", "show", "bnetscale0", "dump").Output()
	lines := strings.Split(strings.TrimSpace(string(out)), "\n")

	rx, tx := "0", "0"
	handshake := "never"
	if len(lines) > 0 && lines[0] != "" {
		parts := strings.Split(lines[0], "\t")
		if len(parts) >= 6 {
			rx = parts[5]
			tx = parts[4]
			if parts[3] != "0" {
				handshake = parts[3]
			}
		}
	}

	fmt.Printf("Status      : Connected\n")
	fmt.Printf("Project     : %s\n", cfg.ProjectID)
	fmt.Printf("IP          : %s\n", cfg.AssignedIP)
	fmt.Printf("Device      : %s\n", cfg.DeviceID)
	fmt.Printf("Handshake   : %s\n", handshake)
	fmt.Printf("RX          : %s bytes\n", rx)
	fmt.Printf("TX          : %s bytes\n", tx)
	_ = out
}
