cat >> inventory/prod.aws_ec2.yml <<'YML'
# inventory hostname = Name tag (host_vars, --limit, output); connect via the private IP
hostnames:
  - tag:Name
compose:
  ansible_host: private_ip_address
YML
ap site.yml
