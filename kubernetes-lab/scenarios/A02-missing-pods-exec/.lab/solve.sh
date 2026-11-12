sed -i 's|^  - {apiGroups: \[""\], resources: \[pods/log\], verbs: \[get\]}|  - {apiGroups: [""], resources: [pods/log], verbs: [get]}\n  - {apiGroups: [""], resources: [pods/exec], verbs: [create, get]}|' rbac.yaml
kx apply -f rbac.yaml >/dev/null
