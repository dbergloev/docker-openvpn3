#!/bin/bash

# Stopping the windscribe service
while read dev; do
    echo "Disconnecting interface $dev"
    openvpn3 session-manage --interface $dev --disconnect
done < <(ip r | grep -e '^0.0.0.0/1 ' | awk '{print $NF}')

if ip r | grep -qe '^0.0.0.0/1 '; then
    # Failed to disconnect. 
    # Manual cleanup
    
    echo "Manually stopping OpenVPN connections"
    for pid in $(ps -A | grep openvpn3 | tac | awk '{print $1}'); do
        kill -s SIGKILL $pid
    done
    
    while read dev; do
        echo "Manually cleaning up routes and addresses for interface $dev"
    
        # Reset the TUN interface
        inet=$(ip -f inet addr show $dev 2>/dev/null | awk '/inet / {print $2}')
        if [ -n "$inet" ]; then
            ip address del $inet dev $dev
        fi
        
        # Cleanup routes
        while read line; do
            ip r del $line
        
        done < <(ip r | grep $dev)
        
    done < <(ip r | grep -e '^0.0.0.0/1 ' | awk '{print $NF}')
fi

# Remove the TUN device
rm /dev/net/tun

# Reset iptables
echo "Re-setting iptable rules"
iptables -F
iptables -X

# Restore DNS
if [ -f /etc/resolv.conf-bak ]; then
    echo "Restoring DNS information to default"
    cat /etc/resolv.conf-bak > /etc/resolv.conf
    rm /etc/resolv.conf-bak
fi

if [ -f /app/app-disconnected.sh ]; then
    /app/app-disconnected.sh
fi

echo "VPN is stopped and disconnected"

