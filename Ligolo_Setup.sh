#!/bin/bash

set -e

PORT=${1:-8443}
WORKDIR="$(pwd)"
ARCH="linux_amd64"
GH_REPO="https://api.github.com/repos/nicocha30/ligolo-ng/releases/latest"

# Fetch latest version tag
echo "[*] Checking for latest Ligolo-NG release..."
TAG=$(curl -s "$GH_REPO" | grep '"tag_name":' | cut -d '"' -f4)
echo "[+] Latest version: $TAG"

# Define expected filenames
AGENT_LINUX="ligolo-ng_agent_${TAG#v}_${ARCH}.tar.gz"
AGENT_WINDOWS="ligolo-ng_agent_${TAG#v}_windows_amd64.zip"
PROXY_LINUX="ligolo-ng_proxy_${TAG#v}_${ARCH}.tar.gz"

# Download base URL
BASE_URL="https://github.com/nicocha30/ligolo-ng/releases/download/$TAG"

# Download and extract agent (Linux)
if [[ ! -f "agent" ]]; then
    echo "[*] Downloading $AGENT_LINUX..."
    curl -LO "$BASE_URL/$AGENT_LINUX"
    echo "[*] Extracting $AGENT_LINUX..."
    tar -xzf "$AGENT_LINUX" -C "$WORKDIR"
    rm -f "$AGENT_LINUX"
    echo "[+] agent (Linux) ready."
fi

# Download and extract agent (Windows)
if [[ ! -f "agent.exe" ]]; then
    echo "[*] Downloading $AGENT_WINDOWS..."
    curl -LO "$BASE_URL/$AGENT_WINDOWS"
    echo "[*] Extracting $AGENT_WINDOWS..."
    unzip -o "$AGENT_WINDOWS" -d "$WORKDIR"
    rm -f "$AGENT_WINDOWS"
    echo "[+] agent.exe (Windows) ready."
fi

# Download and extract proxy
if [[ ! -f "proxy" ]]; then
    echo "[*] Downloading $PROXY_LINUX..."
    curl -LO "$BASE_URL/$PROXY_LINUX"
    echo "[*] Extracting $PROXY_LINUX..."
    tar -xzf "$PROXY_LINUX" -C "$WORKDIR"
    rm -f "$PROXY_LINUX"
    echo "[+] proxy ready."
fi

# Prompt for route
read -p "Enter the route to add (leave blank to skip): " ROUTE

# Create TUN interface
sudo ip tuntap add user kali mode tun ligolo || true
sudo ip link set ligolo up

# Add route if specified
if [[ -n "$ROUTE" ]]; then
    sudo ip route add "$ROUTE" dev ligolo
    echo "Route $ROUTE added to device ligolo."
else
    echo "No route added."
fi

# Start Ligolo proxy
echo "[*] Starting Ligolo proxy on port $PORT..."
sudo ./proxy -selfcert -laddr 0.0.0.0:$PORT
