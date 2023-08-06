#!/bin/bash

# Stopping the windscribe service
openvpn3 session-manage --interface tun0 --disconnect

if ip r | grep -qe '^0.0.0.0/1 '; then
    # Failed to disconnect. 
    # Manual cleanup
    
    for pid in $(ps -A | grep openvpn3 | tac | awk '{print $1}'); do
        kill -s SIGKILL $pid
    done
    
    # Reset the TUN interface
    inet=$(ip -f inet addr show tun0 2>/dev/null | awk '/inet / {print $2}')
    if [ -n "$inet" ]; then
        ip address del $inet dev tun0
    fi
    
    # Cleanup routes
    while read line; do
        ip r del $line
    
    done < <(ip r | grep tun0)
fi

# Remove the TUN device
rm /dev/net/tun

# Reset iptables
iptables -F
iptables -X

# Restore DNS
if [ -f /etc/resolv.conf-bak ]; then
    cat /etc/resolv.conf-bak > /etc/resolv.conf
    rm /etc/resolv.conf-bak
fi

if [ -f /app/app-disconnected.sh ]; then
    /app/app-disconnected.sh
fi

echo "VPN is stopped and disconnected"

