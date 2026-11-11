kx -n argocd patch application lab-apps --type merge -p '{"spec":{"source":{"directory":{"recurse":true}}}}' >/dev/null
W="$LAB_DIR/workspace/gitops"
git -C "$W" pull -q
python3 - "$W/bootstrap/root.yaml" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
s = s.replace("    path: apps\n", "    path: apps\n    directory:\n      recurse: true\n", 1)
open(p, "w").write(s)
PY
git -C "$W" commit -qam "root app: read apps/ recursively (teams keep apps under apps/<team>/) (INC-2352)"
git -C "$W" push -q origin main 2>/dev/null
argo_refresh lab-apps
retry 240 argo_app_ok metrics || true
