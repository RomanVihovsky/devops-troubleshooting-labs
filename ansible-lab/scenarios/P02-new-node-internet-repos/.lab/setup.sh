ws_commit "web node play"
reimage() { nx web2 "rm -f /etc/yum.repos.d/*.repo && cp /root/repos.orig/*.repo /etc/yum.repos.d/ && dnf clean all -q"; }
reimage
ap site.yml || true
