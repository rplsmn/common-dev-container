#!/bin/bash
# Build script for the development container image
# Run this script to build the container image before starting the service

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_NAME="devcontainer:latest"

echo "=== Building Development Container Image ==="
echo "Image name: localhost/${IMAGE_NAME}"
echo ""

# Get current user's UID/GID for proper permissions
USER_UID=$(id -u)
USER_GID=$(id -g)

echo "Building with UID=${USER_UID}, GID=${USER_GID}"
echo ""

podman build \
    --build-arg USER_UID="${USER_UID}" \
    --build-arg USER_GID="${USER_GID}" \
    -t "${IMAGE_NAME}" \
    -f "${SCRIPT_DIR}/Containerfile" \
    "${SCRIPT_DIR}"

echo ""
echo "=== Build Complete ==="
echo ""
echo "Image built: localhost/${IMAGE_NAME}"
echo ""
echo "Next steps:"
echo "1. Create ~/devmachine directory if it doesn't exist:"
echo "   mkdir -p ~/devmachine"
echo ""
echo "2. Install the Quadlet service:"
echo "   mkdir -p ~/.config/containers/systemd"
echo "   cp ${SCRIPT_DIR}/devcontainer-pod.container ~/.config/containers/systemd/"
echo ""
echo "3. Enable and start the service:"
echo "   systemctl --user daemon-reload"
echo "   systemctl --user enable --now devcontainer-pod"
echo ""
echo "4. Check status:"
echo "   systemctl --user status devcontainer-pod"
echo "   podman ps"
echo ""
echo "5. In VS Code, use 'Dev Containers: Attach to Running Container'"
echo "   and select 'devcontainer'"
