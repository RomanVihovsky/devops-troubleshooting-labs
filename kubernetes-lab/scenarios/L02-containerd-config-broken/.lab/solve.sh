nxi k8s-w1 >/dev/null <<'__X__'
set -eu
python3 - <<'PY'
f = "/etc/containerd/config.toml"
lines = open(f).read().split("\n")
hdr = "[plugins.'io.containerd.cri.v1.images']"
out = [l for l in lines if l.strip() not in ("# OPS-31: faster image pulls", "[plugins.'io.containerd.cri.v1.images'", "max_concurrent_downloads = 10")]
i = out.index(hdr)
out.insert(i + 1, "  max_concurrent_downloads = 10")
open(f, "w").write("\n".join(out))
PY
containerd config dump >/dev/null
systemctl restart containerd
__X__
ready() { [ "$(kx get node k8s-w1 -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}')" = True ]; }
retry 120 ready || true
