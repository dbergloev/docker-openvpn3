#
# At the time of creating this, debian 12 has not yet
# been added to the openvpn3 repos. 
#
FROM debian:11

# Build arguments
ARG BUILD_DATE
ARG VCS_REF
ARG VERSION=0.9

# Labels
LABEL eu.dbergloev.build-date=$BUILD_DATE \
      eu.dbergloev.vcs-url="https://github.com/dk-zero-cool/docker-openvpn3.git" \
      eu.dbergloev.schema-version=$VERSION

# The volume for the docker_user home directory, and where configuration files should be stored.
VOLUME [ "/app" ]

# Some environment variables
ENV TZ=America/Toronto \
    PUID=1000 \
    PGID=1000 \
    OVPN="" \
    DNS="1.1.1.1,1.0.0.1"
    
ADD init /opt/init/

# Install required packages
RUN apt-get -y update && apt-get -y dist-upgrade \
        && apt-get install -y tini iptables curl net-tools iproute2 iputils-ping gnupg lsb-release procps \
        && curl -fsSL https://swupdate.openvpn.net/repos/openvpn-repo-pkg-key.pub | gpg --dearmor | tee /etc/apt/trusted.gpg.d/openvpn-repo-pkg-keyring.gpg >/dev/null \
        && curl -fsSL https://swupdate.openvpn.net/community/openvpn3/repos/openvpn3-$(lsb_release -c | awk '{print $2}').list -o /etc/apt/sources.list.d/openvpn3.list \
        && apt-get -y update && apt-get install -y openvpn3 \
        && addgroup --system docker_group  && adduser --system --home /app docker_user && usermod -g docker_group docker_user \
        && chmod +x /opt/init/* \
        && apt-get purge -y lsb-release && apt-get -y autoremove && apt-get -y clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Enable the health check for the VPN and app
# HEALTHCHECK --interval=1m --timeout=30s --start-period=45s --start-interval=5s \
HEALTHCHECK --interval=1m --timeout=30s --start-period=30s \
  CMD /bin/bash /opt/init/health-check.sh || exit 1
  
# Run the container
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/opt/init/run.sh"]

