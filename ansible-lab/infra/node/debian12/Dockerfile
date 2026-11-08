# ansible-lab managed node: Debian 12 with real systemd (PID 1), sshd, python3 (+python3-apt for the apt
# module), sudo. Packages beyond this come from the internal mirror http://repo.acme.internal/debian.
# NOT privileged: same container hygiene as ../../linux-lab/infra/server.
ARG BASE=debian:12
FROM ${BASE}
ENV container=docker DEBIAN_FRONTEND=noninteractive
RUN set -eux; \
    for i in 1 2 3 4 5; do apt-get update && break || sleep 5; done; \
    for i in 1 2 3 4 5; do apt-get install -y --no-install-recommends \
      systemd systemd-sysv dbus openssh-server sudo python3 python3-apt \
      ca-certificates curl iproute2 iputils-ping procps less vim-tiny dpkg-dev \
      && break || sleep 5; done; \
    rm -rf /var/lib/apt/lists/*
RUN systemctl mask systemd-udevd.service systemd-udevd-kernel.socket systemd-udevd-control.socket \
      systemd-logind.service getty@.service autovt@.service console-getty.service getty.target \
      systemd-remount-fs.service systemd-sysctl.service systemd-modules-load.service \
      kmod-static-nodes.service systemd-binfmt.service proc-sys-fs-binfmt_misc.automount \
      proc-sys-fs-binfmt_misc.mount systemd-timesyncd.service systemd-hwdb-update.service \
      systemd-firstboot.service systemd-random-seed.service systemd-journald-audit.socket \
      systemd-tmpfiles-setup-dev.service systemd-pstore.service swap.target \
      dev-hugepages.mount dev-mqueue.mount sys-fs-fuse-connections.mount \
      sys-kernel-config.mount sys-kernel-debug.mount sys-kernel-tracing.mount; \
    systemctl enable ssh; \
    rm -f /etc/ssh/ssh_host_*; \
    sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
COPY ssh-hostkeys.service /etc/systemd/system/ssh-hostkeys.service
RUN systemctl enable ssh-hostkeys.service
# the account Ansible uses (key installed by ./lab at start); passwordless sudo unless a scenario says otherwise
RUN useradd -m -s /bin/bash -u 1000 ansible && echo 'ansible ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/ansible \
    && chmod 0440 /etc/sudoers.d/ansible && passwd -l root && rm -f /usr/sbin/policy-rc.d \
    && cp /etc/apt/sources.list.d/debian.sources /root/debian.sources.orig \
    && rm -f /etc/apt/sources.list.d/debian.sources \
    && echo 'deb [trusted=yes] http://repo.acme.internal/debian ./' > /etc/apt/sources.list.d/acme.list
COPY lab-init /usr/local/sbin/lab-init
STOPSIGNAL SIGRTMIN+3
CMD ["/usr/local/sbin/lab-init"]
