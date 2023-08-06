#!/bin/bash

# Change docker user/group ids
usermod -u $PUID docker_user 2>/dev/null
groupmod -g $PGID docker_group 2>/dev/null
chown -R docker_user:docker_group /app

# Make sure that scripts are executable
chmod +x /opt/init/*.sh
chmod +x /app/app-*.sh 2>/dev/null

if [ -f /app/app-init.sh ]; then
    echo "Running custom app init"
    bash /app/app-init.sh
fi

if ! /opt/init/vpn-connect.sh; then
    exit 1

elif [ -f /app/app-run.sh ]; then
    echo "Launching custom app run environment"
    su -w VPN_PORT -g docker_group - docker_user -c "bash /app/app-run.sh" >/proc/1/fd/1 2>/proc/1/fd/2

else
    trap : TERM INT; sleep infinity & echo $! > /var/run/init.pid; wait
fi

