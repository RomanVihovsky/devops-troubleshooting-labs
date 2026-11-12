# L16 - the node's clock, not its certificates

**Root cause**: chrony was stopped and disabled on `k8s-w1`, and the clock was set 400 days back. Every
certificate the kubelet sees (its own client cert, the API server's) has a `notBefore` in that node's
"future". TLS fails with *certificate has expired or is not yet valid*, the kubelet can't renew its Lease,
and the node goes NotReady. The certificates were fine all along.

**Diagnosis**
```
./lab node w1
date -u; ssh <another node> date -u
sudo journalctl -u kubelet --since -5min | grep -m3 x509
openssl x509 -noout -dates -in /var/lib/kubelet/pki/kubelet-client-current.pem   # notBefore is "in the future"
systemctl status chrony; chronyc tracking
```

**Fix**: `systemctl enable --now chrony`, `chronyc makestep`. The kubelet reconnects by itself.

**Interview notes**
- Read both halves of "expired **or not yet valid**". Compare the clock with `notBefore`/`notAfter` before
  renewing anything. Renewing certs on a node with a wrong clock produces certs that are wrong too.
- Kubernetes needs synced clocks: TLS validity, token expiry (`exp`/`nbf` of ServiceAccount tokens), Lease
  renewals, etcd (raft timing on control-plane nodes), log correlation.
- chrony vs ntpd vs systemd-timesyncd. `makestep` decides whether a big offset is **stepped** (jump) or
  **slewed** (slowly, at most ~0.5 ms/s, so days to fix minutes). The lab uses `makestep 1 -1` because a
  sleeping host leaves VMs hours behind.
- Validity is checked at the TLS **handshake**: open connections kept working until the kubelet restarted.
  A clock jump can stay hidden for hours, then break everything at the next reconnect.
- A licence tool that needs a fixed date belongs in a container with a faked time (libfaketime), never on a
  cluster node.
