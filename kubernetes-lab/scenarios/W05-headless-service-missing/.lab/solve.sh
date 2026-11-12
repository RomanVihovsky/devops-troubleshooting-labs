kx apply -f - >/dev/null <<'YML'
apiVersion: v1
kind: Service
metadata: {name: web, namespace: kv}
spec: {clusterIP: None, selector: {app: web}, ports: [{port: 8080}]}
YML
