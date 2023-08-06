#!/bin/bash

if [[ -z "$OVPN" || ! -f "$OVPN" ]]; then
    echo "Missing VPN profile" >&2
    exit 2
    
elif [ -f /dev/net/tun ]; then
    /opt/init/disconnect.sh
fi

if ! pgrep dbus-daemon >/dev/null 2>&1; then
    echo "Starting the DBUS daemon"
    /etc/init.d/dbus start
    
    ts=$(date +%s)
    while :; do
        td=$(( $(date +%s) - $ts ))
        
        if ! netstat -a | grep 'LISTENING' | grep -q '/run/dbus/system_bus_socket'; then
            if [ $td -lt 10 ]; then
                sleep 0.2
                continue
            fi
            
            echo "Timed out waiting on DBUS" >&2
            exit 2
        fi
        
        break
    done
fi

# Create a TUN device
mkdir -p /dev/net 2>/dev/null
mknod /dev/net/tun c 10 200
chmod 0666 /dev/net/tun

echo "Connecting to remote server at $(grep -e '^remote ' "$OVPN" | awk '{print $2}')"

if ! openvpn3 session-start --config $OVPN --timeout 20 --persist-tun \
        || ! ip r | grep -qe '^0.0.0.0/1 '; then
        
    echo "Failed to connect to the VPN" >&2
    exit 1
    
elif [ -n "$DNS" ]; then
    # Update DNS
    cp /etc/resolv.conf /etc/resolv.conf-bak
    echo "" > /etc/resolv.conf
    
    for ip in $(echo $DNS | sed 's/,/ /'); do
        echo "nameserver $ip" >> /etc/resolv.conf
    done
fi

# Wait for the connection to come up
ts=$(date +%s)
while :; do
    td=$(( $(date +%s) - $ts ))
    
    echo "Waiting for the VPN connection to complete... $td seconds"
    
    if ! ping -c 1 $(grep -e '^remote ' "$OVPN" | awk '{print $2}') >/dev/null 2>&1; then
        if [ $td -ge 20 ]; then
            exit 1
        fi
        
        sleep 0.2
        continue
    fi
    
    break
done

if [ -f /app/app-connected.sh ]; then
    /app/app-connected.sh
fi

if [ -f /app/iptables.rules ]; then
    echo "Restoring custom iptables rules"
    /usr/sbin/iptables-restore /app/iptables.rules
fi

echo "VPN is connected and running"

exit 0

