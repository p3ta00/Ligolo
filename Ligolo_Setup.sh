#!/bin/bash

PORT=${1:-8443}

# Prompt for route before launching ligolo
read -p "Enter the route to add (leave blank to skip): " ROUTE

# Create TUN interface
sudo ip tuntap add user kali mode tun ligolo

# Set interface up
sudo ip link set ligolo up

# Check if ROUTE is non-empty
if [[ -n "$ROUTE" ]]; then
    sudo ip route add "$ROUTE" dev ligolo
    echo "Route $ROUTE added to device ligolo."
else
    echo "No route added."
fi

# Start Ligolo proxy in the background with nohup
sudo ./proxy -selfcert -laddr 0.0.0.0:$PORT
