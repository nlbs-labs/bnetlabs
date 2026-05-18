package config

import (
	"encoding/json"
	"os"
	"path/filepath"
)

const (
	DirName  = "bnetscale"
	DirMode  = 0700
	KeyMode  = 0600
)

type Peer struct {
	PublicKey  string `json:"public_key"`
	AssignedIP string `json:"assigned_ip"`
	Name       string `json:"name"`
}

type Config struct {
	ServerURL    string `json:"server_url"`
	ProjectID    string `json:"project_id"`
	DeviceID     string `json:"device_id"`
	AssignedIP   string `json:"assigned_ip"`
	PrivateKey   string `json:"-"`
	WGServerPub  string `json:"wg_server_pub"`
	WGEndpoint   string `json:"wg_endpoint"`
	SessionToken string `json:"session_token"`
	Peers        []Peer `json:"peers"`
}

func Dir() (string, error) {
	base := "/etc"
	if v := os.Getenv("BNETSCALE_CONFIG_DIR"); v != "" {
		base = v
	}
	dir := filepath.Join(base, DirName)
	if err := os.MkdirAll(dir, DirMode); err != nil {
		return "", err
	}
	return dir, nil
}

func ConfigPath() (string, error) {
	dir, err := Dir()
	if err != nil {
		return "", err
	}
	return filepath.Join(dir, "config.json"), nil
}

func KeyPath() (string, error) {
	dir, err := Dir()
	if err != nil {
		return "", err
	}
	return filepath.Join(dir, "private.key"), nil
}

func Load() (*Config, error) {
	path, err := ConfigPath()
	if err != nil {
		return nil, err
	}

	data, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}

	var cfg Config
	if err := json.Unmarshal(data, &cfg); err != nil {
		return nil, err
	}

	keyPath, err := KeyPath()
	if err != nil {
		return nil, err
	}
	keyData, err := os.ReadFile(keyPath)
	if err != nil {
		return nil, err
	}
	cfg.PrivateKey = string(keyData)

	return &cfg, nil
}

func Save(cfg *Config) error {
	path, err := ConfigPath()
	if err != nil {
		return err
	}

	data, err := json.MarshalIndent(cfg, "", "  ")
	if err != nil {
		return err
	}

	if err := os.WriteFile(path, data, KeyMode); err != nil {
		return err
	}

	if cfg.PrivateKey != "" {
		keyPath, err := KeyPath()
		if err != nil {
			return err
		}
		if err := os.WriteFile(keyPath, []byte(cfg.PrivateKey), KeyMode); err != nil {
			return err
		}
	}

	return nil
}

func PrivateKeyPath() (string, error) {
	dir, err := Dir()
	if err != nil {
		return "", err
	}
	return filepath.Join(dir, "private.key"), nil
}

func PublicKeyPath() (string, error) {
	dir, err := Dir()
	if err != nil {
		return "", err
	}
	return filepath.Join(dir, "public.key"), nil
}

func FingerprintPath() (string, error) {
	dir, err := Dir()
	if err != nil {
		return "", err
	}
	return filepath.Join(dir, "fingerprint.txt"), nil
}

func ConfigExists() bool {
	path, err := ConfigPath()
	if err != nil {
		return false
	}
	_, err = os.Stat(path)
	return err == nil
}

func RemoveAll() error {
	dir, err := Dir()
	if err != nil {
		return err
	}
	return os.RemoveAll(dir)
}
