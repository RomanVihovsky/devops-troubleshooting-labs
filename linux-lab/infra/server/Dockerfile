# The lab "server": Debian 12 with real systemd as PID 1, the usual services
# (nginx, sshd, cron, rsyslog, dnsmasq) and a troubleshooting toolbox.
FROM debian:12

ENV container=docker DEBIAN_FRONTEND=noninteractive

RUN set -eux; \
    for i in 1 2 3 4 5; do apt-get update && break || sleep 5; done; \
    for i in 1 2 3 4 5; do apt-get install -y --no-install-recommends \
      systemd systemd-sysv dbus \
      nginx openssh-server openssh-client cron rsyslog logrotate sudo dnsmasq-base \
      python3 jq openssl ca-certificates curl wget netcat-openbsd \
      procps psmisc htop sysstat iotop strace ltrace gdb lsof file less vim-tiny nano \
      iproute2 iputils-ping dnsutils net-tools iptables tcpdump traceroute \
      attr acl e2fsprogs util-linux inotify-tools bash-completion man-db \
      && break || sleep 5; done; \
    rm -rf /var/lib/apt/lists/*

# systemd-in-a-container hygiene. The container is NOT privileged; still, mask every
# unit that would try to touch host-level things (devices, VTs/seats, kernel
# modules, global sysctls, clock, binfmt, swap).
RUN systemctl mask systemd-udevd.service systemd-udevd-kernel.socket systemd-udevd-control.socket \
      systemd-logind.service getty@.service autovt@.service console-getty.service getty.target \
      systemd-remount-fs.service systemd-sysctl.service systemd-modules-load.service \
      kmod-static-nodes.service systemd-binfmt.service proc-sys-fs-binfmt_misc.automount \
      proc-sys-fs-binfmt_misc.mount systemd-timesyncd.service systemd-hwdb-update.service \
      systemd-firstboot.service systemd-random-seed.service systemd-journald-audit.socket \
      systemd-tmpfiles-setup-dev.service systemd-pstore.service swap.target \
      dev-hugepages.mount dev-mqueue.mount sys-fs-fuse-connections.mount \
      sys-kernel-config.mount sys-kernel-debug.mount sys-kernel-tracing.mount; \
    systemctl enable ssh nginx cron rsyslog; \
    rm -f /etc/nginx/sites-enabled/default /etc/ssh/ssh_host_*; \
    sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config

# regenerate ssh host keys on first boot of every fresh container
COPY ssh-hostkeys.service /etc/systemd/system/ssh-hostkeys.service
RUN systemctl enable ssh-hostkeys.service

# users: admin = you (sudo), deploy = an app/CI account
RUN useradd -m -s /bin/bash -u 1000 admin && echo 'admin ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/admin \
    && chmod 0440 /etc/sudoers.d/admin \
    && useradd -m -s /bin/bash -u 1001 deploy \
    && passwd -l root

COPY nginx-default.conf /etc/nginx/sites-enabled/default
COPY motd /etc/motd
COPY bashrc-lab /etc/profile.d/zz-lab.sh

COPY lab-init /usr/local/sbin/lab-init
STOPSIGNAL SIGRTMIN+3
CMD ["/usr/local/sbin/lab-init"]
