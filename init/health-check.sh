#!/bin/bash

if ! openvpn3 session-stats --interface tun0 >/dev/null 2>&1 || ! ip r | grep -qe '^0.0.0.0/1 '; then
    echo "Health check failed at $(date +'%Y-%m-%d %H:%M')" >/proc/1/fd/2
    
    /opt/init/vpn-connect.sh >/proc/1/fd/1 2>/proc/1/fd/2; ret=$?
    
    if [ $ret -ne 0 ]; then
        if [[ $ret -eq 2 && -f /var/run/init.pid ]]; then
            kill -s SIGKILL $(cat /var/run/init.pid)
        fi
        
        exit $?
    fi

else
    ts=$(date +%s)
    while :; do
        td=$(( $(date +%s) - $ts ))
        
        if ! ping -c 1 $(grep -e '^remote ' "$OVPN" | awk '{print $2}') >/dev/null 2>&1; then
            if [ $td -ge 20 ]; then
                echo "Health check failed at $(date +'%Y-%m-%d %H:%M')" >/proc/1/fd/2
                echo "Network is down, re-setting windscribe connection" >/proc/1/fd/2
                
                /opt/init/vpn-connect.sh >/proc/1/fd/1 2>/proc/1/fd/2; ret=$?
                
                if [ $ret -ne 0 ]; then
                    if [[ $ret -eq 2 && -f /var/run/init.pid ]]; then
                        kill -s SIGKILL $(cat /var/run/init.pid)
                    fi
                    
                    exit $ret
                fi
            fi
            
            sleep 0.2
            continue
        fi
        
        break
    done
fi

# Check the app health
if [ -f /app/app-health-check.sh ]; then
    if ! bash /app/app-health-check.sh >/proc/1/fd/1 2>/proc/1/fd/2; then
        exit 1
    fi
fi

exit 0

