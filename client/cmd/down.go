package cmd

import (
	"fmt"
	"os"
	"os/exec"
)

func Down(args []string) {
	ifaceName := "bnetscale0"

	cmds := [][]string{
		{"ip", "link", "delete", ifaceName},
	}

	for _, cmdArgs := range cmds {
		if err := exec.Command(cmdArgs[0], cmdArgs[1:]...).Run(); err != nil {
			fmt.Fprintf(os.Stderr, "Warning: %v\n", err)
		}
	}

	if len(args) > 0 && args[0] == "--purge" {
		os.RemoveAll("/etc/bnetscale")
		fmt.Println("Config purged.")
	}

	fmt.Println("Tunnel down.")
}
