# Docker OpenVPN 3 Image

## About the image

Connect to a VPN Server using the newer [OpenVPN 3](https://openvpn.net/cloud-docs/owner/connectors/connector-user-guides/openvpn-3-client-for-linux.html) client. 

This can be used by other containers in the following way:

 1. Set a container to use the OpenVPN container network. This way you keep the VPN and the apps using it seprately from one another. It also allows you to use the same VPN connection for multiple containers. 
 
 2. Extend this image and build your application into it. Preparations for this is already included in this image.
 
 3. Launch this image and mount your app directory to `/app` in the container _(#See: Extending the image)_
 
## Extending the image

To extend this image you simply need to place a single file into the `/app` directory called `app-run.sh`. This file will be executed on container start after the VPN has been configured and started. This file is executed as the `PUID` user. 

You can optionally include `app-init.sh` which is executed before anything else, even before the VPN has been setup. This file is executed as `root` and allows for app configurations before luanch. 

Another optional file is `app-health-check.sh` which is periodically called to check the health state of the app. This should exit with status codes such as `0` for `HEALTHY`.

Lastly there are the optional files `app-connected.sh` and `app-disconnected.sh`. These are executed whenever the VPN state changes.

### Keep running

When the file `app-run.sh` is available, it becomes it's job to keep the container alive. If the file exists then the container will shut down. This control is passed to the `app-run.sh` to give custom applications full control of the containers lifecicle. 

It is also a good idea to update `/var/run/init.pid` with the correct `pid` that keeps the container running so to allow things like `health check` to signal the process to stop. 

__Example__

You could add something like this to the end of the `app-init.sh` script. 

```sh
trap : TERM INT; sleep infinity & echo $! > /var/run/init.pid; wait
```

## Usage

### docker

```
docker create \
  --name=docker-openvpn3 \
  -e PUID=1000 \
  -e PGID=1000 \
  -e TZ=America/New_York \
  -e DNS=1.1.1.1,1.0.0.1 \
  -e OVPN=/app/myconf.ovpn \
  -v /location/on/host:/app \
  --cap-add NET_ADMIN \
  --restart unless-stopped \
  <BUILD_NAME>/docker-openvpn3:latest
```

## Parameters

| Parameter | Example | Description |
| :----: | --- | --- |
| PUID | 1000 | The nummeric user ID to run the application as, and assign to the user docker_user |
| PGID | 1000 | The numeric group ID to run the application as, and assign to the group docker_group |
| TZ | Europe/London | The timezone to run the container in |
| DNS | 1.1.1.1,1.0.0.1 | DNS Servers to use when connected to the VPN |
| OVPN | /app/myconf.ovpn | The Configuration file for OpenVPN |

## Volumes

| Volume | Description |
| :----: | --- |
| /app | The home directory of docker_user `PUID` |

## Building locally

```
git clone https://github.com/dk-zero-cool/docker-openvpn3.git
cd docker-openvpn3
docker build \
  --no-cache \
  -t <BUILD_NAME>/docker-openvpn3:latest .
```

