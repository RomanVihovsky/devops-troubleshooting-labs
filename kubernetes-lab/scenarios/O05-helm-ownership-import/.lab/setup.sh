# O05: the Service the chart renders already exists, without Helm's ownership metadata
kns importx
kx -n importx create deployment web-old --image=registry.lab:5000/lab/labapp:1.4 --dry-run=client -o yaml | ka -f -
kx -n importx apply -f - >/dev/null <<'YML'
apiVersion: v1
kind: Service
metadata: {name: web, namespace: importx, labels: {lab.k8slab/scenario: O05}}
spec:
  selector: {app.kubernetes.io/name: labapp, app.kubernetes.io/instance: web}
  ports: [{name: http, port: 8080, targetPort: http}]
YML
remember o05_uid "$(kx -n importx get svc web -o jsonpath='{.metadata.uid}')"
helm install web "$LAB_DIR/charts/labapp" -n importx -f values.yaml >/dev/null 2>&1 && die "helm install worked"
helm uninstall web -n importx >/dev/null 2>&1 || true
true
