package cmd

import (
	"os"
	"os/exec"
	"syscall"
)

func ensureRoot() {
	if os.Geteuid() == 0 {
		return
	}

	args := append([]string{"sudo"}, os.Args...)
	c := exec.Command(args[0], args[1:]...)
	c.Stdin = os.Stdin
	c.Stdout = os.Stdout
	c.Stderr = os.Stderr
	c.SysProcAttr = &syscall.SysProcAttr{}

	if err := c.Run(); err != nil {
		os.Exit(1)
	}
	os.Exit(0)
}
