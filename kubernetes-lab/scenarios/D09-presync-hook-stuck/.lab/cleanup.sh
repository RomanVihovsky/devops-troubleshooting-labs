# Argo CD puts a finalizer on hook resources (argocd.argoproj.io/hook-finalizer); with the app gone nobody removes
# it, and namespace billing would hang in Terminating
for r in $(kx -n billing get jobs,pods,sealedsecrets -o name 2>/dev/null); do
  kx -n billing patch "$r" --type merge -p '{"metadata":{"finalizers":null}}' >/dev/null 2>&1
done
true
