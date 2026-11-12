# OpenBao on k8s-gw (/etc/openbao/openbao.hcl). Integrated storage (raft, single node - OpenBao 2.7 has no
# "file" backend). TLS from the lab CA; auto-unseal with a static key file -
# lab-grade on purpose (scenario Y06 breaks it). Recovery keys + root token live on the desktop (.state/openbao).
ui           = true
api_addr     = "https://bao.lab:8200"
cluster_addr = "https://bao.lab:8201"

storage "raft" {
  path    = "/var/lib/openbao/data"
  node_id = "k8s-gw"
}

listener "tcp" {
  address       = "0.0.0.0:8200"
  tls_cert_file = "/etc/openbao/tls/bao.crt"
  tls_key_file  = "/etc/openbao/tls/bao.key"
}

seal "static" {
  current_key_id = "k8slab-1"
  current_key    = "file:///etc/openbao/unseal.key"
}
