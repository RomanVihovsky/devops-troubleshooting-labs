# ansible-lab managed node: Rocky Linux 9 with real systemd (PID 1), sshd, python3, sudo.
# Packages beyond this come from the internal mirror http://repo.acme.internal/rocky9.
# NOT privileged: same container hygiene as the Debian node.
ARG BASE=rockylinux/rockylinux:9
FROM ${BASE}
ENV container=docker
RUN set -eux; \
    for i in 1 2 3 4 5; do dnf -y install --setopt=install_weak_deps=False \
      systemd openssh-server openssh-clients sudo python3 iproute iputils procps-ng less vim-minimal \
      hostname createrepo_c dnf-plugins-core && break || sleep 5; done; \
    dnf clean all
RUN systemctl mask systemd-udevd.service systemd-udevd-kernel.socket systemd-udevd-control.socket \
      systemd-logind.service getty@.service autovt@.service console-getty.service getty.target \
      systemd-remount-fs.service systemd-sysctl.service systemd-modules-load.service \
      kmod-static-nodes.service systemd-binfmt.service proc-sys-fs-binfmt_misc.automount \
      proc-sys-fs-binfmt_misc.mount systemd-hwdb-update.service \
      systemd-firstboot.service systemd-random-seed.service systemd-journald-audit.socket \
      systemd-tmpfiles-setup-dev.service systemd-pstore.service swap.target \
      dev-hugepages.mount dev-mqueue.mount sys-fs-fuse-connections.mount \
      sys-kernel-config.mount sys-kernel-debug.mount sys-kernel-tracing.mount; \
    systemctl enable sshd; \
    rm -f /etc/ssh/ssh_host_*; \
    sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
COPY ssh-hostkeys.service /etc/systemd/system/ssh-hostkeys.service
RUN systemctl enable ssh-hostkeys.service
RUN useradd -m -s /bin/bash -u 1000 ansible && echo 'ansible ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/ansible \
    && chmod 0440 /etc/sudoers.d/ansible && passwd -l root \
    && mkdir -p /root/repos.orig && mv /etc/yum.repos.d/*.repo /root/repos.orig/ \
    && printf '[acme-rocky9]\nname=ACME internal mirror (Rocky 9)\nbaseurl=http://repo.acme.internal/rocky9\nenabled=1\ngpgcheck=0\n' > /etc/yum.repos.d/acme.repo
COPY lab-init /usr/local/sbin/lab-init
STOPSIGNAL SIGRTMIN+3
CMD ["/usr/local/sbin/lab-init"]
