# D07: app.kubernetes.io/version moves INTO labapp.selectorLabels (Deployment selector, Service selector, PDB, ...)
gitops_commit "labapp chart: select pods by version too (per-version routing later)" <<'SNIP'
python3 - <<'PY'
import re
p = "charts/labapp/templates/_helpers.tpl"; s = open(p).read()
s = s.replace('app.kubernetes.io/instance: {{ .Release.Name }}\n{{- end }}',
              'app.kubernetes.io/instance: {{ .Release.Name }}\napp.kubernetes.io/version: {{ include "labapp.imageTag" . | quote }}\n{{- end }}', 1)
s = s.replace('{{ include "labapp.selectorLabels" . }}\napp.kubernetes.io/version: {{ include "labapp.imageTag" . | quote }}\n',
              '{{ include "labapp.selectorLabels" . }}\n', 1)
open(p, "w").write(s)
p = "charts/labapp/templates/deployment.yaml"; s = open(p).read()
s = s.replace('        {{- include "labapp.selectorLabels" . | nindent 8 }}\n        app.kubernetes.io/version: {{ include "labapp.imageTag" . | quote }}\n',
              '        {{- include "labapp.selectorLabels" . | nindent 8 }}\n', 1)
open(p, "w").write(s)
PY
grep -q 'app.kubernetes.io/version' charts/labapp/templates/_helpers.tpl
SNIP
for a in demo shop; do argo_refresh "$a"; done
immutable() { kx -n argocd get application demo -o json | jq -e '.status.operationState.message // "" | test("immutable")' >/dev/null; }
retry 240 immutable || die "the demo sync did not fail on the selector"
