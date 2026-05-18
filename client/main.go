package main

import (
	"fmt"
	"os"

	"git.nafi-labs.tech/Labs/bnetscale/client/cmd"
)

func main() {
	if len(os.Args) < 2 {
		printUsage()
		os.Exit(1)
	}

	command := os.Args[1]
	args := os.Args[2:]

	switch command {
	case "join":
		cmd.Join(args)
	case "up":
		cmd.Up(args)
	case "down":
		cmd.Down(args)
	case "status":
		cmd.Status(args)
	case "version", "-v", "--version":
		fmt.Println("bnetscale v0.1.5")
	case "help", "-h", "--help":
		printUsage()
	default:
		fmt.Fprintf(os.Stderr, "Unknown command: %s\n", command)
		printUsage()
		os.Exit(1)
	}
}

func printUsage() {
	fmt.Println(`BNetScale CLI — Self-hosted Mesh VPN Client

Usage:
  bnetscale join <token> [--server <url>]   Join a project (default: https://bnetscale.nlbs.me)
  bnetscale up                               Bring tunnel up
  bnetscale down                             Bring tunnel down
  bnetscale status                           Show connection status
  bnetscale version, -v                      Show version
  bnetscale help, -h                         Show this help

Examples:
  bnetscale join eyJhbGciOiJIUzI1NiIs...
  bnetscale join <token> --server https://bnetscale.nlbs.me
  bnetscale up
  bnetscale status`)
}
