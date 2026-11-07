# A "VM" for the lab: Docker-in-Docker + the Linux tools you would expect
# on a real swarm host. Every node (manager*/worker*) runs this image.
FROM docker:29-dind

RUN apk add --no-cache \
      bash bash-completion coreutils findutils grep less procps util-linux \
      vim nano jq curl \
      iproute2 iproute2-ss iproute2-tc iputils bind-tools net-tools ethtool \
      tcpdump conntrack-tools mtr iperf3 socat nmap-ncat traceroute \
      strace lsof htop sysstat psmisc

COPY daemon.json /etc/docker/daemon.json
# Pristine copy used by `./lab reset` to undo daemon.json tampering.
COPY daemon.json /usr/share/swarmlab/daemon.json
COPY bashrc /root/.bashrc
COPY motd /etc/motd

ENV DOCKER_TLS_CERTDIR="" \
    DOCKER_IPTABLES_LEGACY=""

CMD ["dockerd", "--host=unix:///var/run/docker.sock"]
