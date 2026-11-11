## Hint 1
`kubectl -n edge describe pod <the w1 pod>` - the pull error names the address it tried. Pull by hand on the
node: `./lab node w1`, `sudo crictl pull registry.lab:5000/lab/labapp:1.3`.

## Hint 2
containerd finds per-registry settings in `/etc/containerd/certs.d/<host:port>/hosts.toml`
(`config_path` in `/etc/containerd/config.toml`). Compare w1's file with w2's.

## Hint 3
Fix `server` / `[host."..."]` in `/etc/containerd/certs.d/registry.lab:5000/hosts.toml` on w1 to
`http://registry.lab:5000`. containerd reads `hosts.toml` per pull (no restart needed); then delete the stuck pod.
