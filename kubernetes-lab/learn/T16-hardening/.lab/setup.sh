# T16: a namespace with an old Secret (written before encryption), no audit log from earlier runs
nx "$CP" 'rm -rf /var/log/kubernetes/audit' </dev/null
kns t16
ka -f - <<'YML'
apiVersion: v1
kind: Secret
metadata: {name: legacy, namespace: t16}
stringData: {password: written-before-encryption}
YML
