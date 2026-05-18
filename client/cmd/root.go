package cmd

import "fmt"

func PrintUsage() {
	fmt.Println(`BNetScale CLI — Self-hosted Mesh VPN Client

Usage:
  bnetscale join <token> [--server <url>]   Join a project
  bnetscale up                               Bring tunnel up
  bnetscale down                             Bring tunnel down
  bnetscale status                           Show connection status
  bnetscale version, -v                      Show version
  bnetscale help, -h                         Show this help

Examples:
  bnetscale join eyJhbGciOiJIUzI1NiIs...
  bnetscale join <token> --server https://vpn.example.com
  bnetscale up
  bnetscale status`)
}
