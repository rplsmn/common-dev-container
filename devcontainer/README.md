# Development Container Setup

This directory contains configuration for a persistent development container using Podman and Quadlet (systemd integration).

## Overview

This setup creates a long-running development container that:
- Persists across host reboots (managed by systemd)
- Mounts `~/devmachine/` from host for your projects
- Mounts SSH keys for GitHub authentication
- Has all development tools pre-installed (Node.js, Python, R, Rust, etc.)
- Works with VS Code "Attach to Running Container" feature

## Prerequisites

- Podman installed (rootless mode)
- VS Code with "Dev Containers" extension
- `~/devmachine/` directory on host
- SSH keys at `~/.ssh/id_ed25519` and `~/.ssh/id_ed25519.pub`

## Quick Start

### 1. Build the Image

```bash
cd devcontainer
chmod +x build.sh
./build.sh
```

This builds the container image with your user's UID/GID for proper file permissions.

### 2. Create Required Directories

```bash
mkdir -p ~/devmachine
mkdir -p ~/.config/containers/systemd
```

### 3. Install the Quadlet Service

```bash
cp devcontainer-pod.container ~/.config/containers/systemd/
```

### 4. Enable and Start

```bash
# Reload systemd to pick up new service
systemctl --user daemon-reload

# Enable (start on boot) and start now
systemctl --user enable --now devcontainer-pod
```

### 5. Verify

```bash
# Check service status
systemctl --user status devcontainer-pod

# Check container is running
podman ps

# Test container access
podman exec -it devcontainer bash
```

## VS Code Integration

1. Install the "Dev Containers" extension in VS Code
2. Open VS Code
3. Press `F1` → "Dev Containers: Attach to Running Container"
4. Select `devcontainer`
5. VS Code will open a new window connected to the container
6. Navigate to `/home/developer/devmachine/<your-repo>`

## Container Contents

| Component | Version/Details |
|-----------|-----------------|
| OS | Ubuntu 24.04 LTS |
| Node.js | 22.x LTS |
| Python | 3.x (system) |
| R | Latest via r-rig |
| Rust | Latest stable |
| Copilot CLI | Latest |
| Claude Code | Latest |
| Mistral Vibe | Latest |

## Managing the Container

### Stop the container
```bash
systemctl --user stop devcontainer-pod
```

### Start the container
```bash
systemctl --user start devcontainer-pod
```

### Restart the container
```bash
systemctl --user restart devcontainer-pod
```

### View logs
```bash
journalctl --user -u devcontainer-pod -f
```

### Disable auto-start
```bash
systemctl --user disable devcontainer-pod
```

### Re-enable auto-start
```bash
systemctl --user enable devcontainer-pod
```

## Rebuilding the Image

When you need to update the container (new tool versions, etc.):

```bash
# Stop the service
systemctl --user stop devcontainer-pod

# Remove old container
podman rm devcontainer

# Rebuild image
./build.sh

# Start service
systemctl --user start devcontainer-pod
```

## Workflow

1. Clone repos into `~/devmachine/` on your host machine
2. The container sees them at `/home/developer/devmachine/`
3. Attach VS Code to the running container
4. Open your project folder inside VS Code
5. Run `npm install`, `npm run dev`, etc. inside the container
6. Changes persist because:
   - Source code is on the mounted host volume
   - Container itself persists (not recreated)
   - `node_modules/` stays inside the container's view of the mount

## Troubleshooting

### Container won't start
```bash
# Check for errors
journalctl --user -u devcontainer-pod --no-pager -n 50

# Try running manually to see errors
podman run --rm -it localhost/devcontainer:latest bash
```

### Permission issues with mounted files
The build script uses your UID/GID. If you have issues:
1. Check your UID: `id -u`
2. Rebuild with correct UID if needed

### SSH keys not working
- Ensure `~/.ssh/id_ed25519` exists and has correct permissions (`chmod 600`)
- The keys are mounted read-only for security

### systemd user services not persisting after logout
Enable lingering for your user:
```bash
sudo loginctl enable-linger $USER
```

## WSL-Specific Notes

If running Podman inside WSL:
1. Ensure Podman is installed in WSL (not Docker Desktop)
2. Enable systemd in WSL: add `[boot] systemd=true` to `/etc/wsl.conf`
3. Restart WSL: `wsl --shutdown` from PowerShell
4. Enable lingering: `sudo loginctl enable-linger $USER`

## Security Notes

- SSH private keys are mounted **read-only** (not copied into image)
- Container runs as non-root user
- Uses rootless Podman (no root privileges needed)
- Git config mounted read-only
