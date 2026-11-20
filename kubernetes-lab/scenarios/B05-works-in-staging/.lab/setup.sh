# B05: pull Secret + ConfigMap only in web-staging, the arm64 tag, ingressClassName nginx - promoted to web-prod
kns web-staging web-prod
for w in $(workers); do nx "$w" 'crictl rmi registry.lab:5001/lab/labapp:1.6 registry.lab:5001/lab/labapp:1.4 >/dev/null 2>&1; true' </dev/null; done
kx -n web-staging create secret docker-registry regcred --docker-server=registry.lab:5001 --docker-username=ci \
  --docker-password="$(registry_ci_password)" --dry-run=client -o yaml | ka -f -
kx -n web-staging create configmap web-config --from-literal=GREETING=Howdy --from-literal=APP_NAME=web --dry-run=client -o yaml | ka -f -
remember b05_staging "$(kx -n web-staging get secret regcred configmap web-config -o jsonpath='{.items[*].metadata.resourceVersion}')"
ka -f web.yaml
denied() { kx -n web-prod get pods -l app=web -o jsonpath='{.items[*].status.containerStatuses[*].state.waiting.reason}' | grep -qE 'ImagePullBackOff|ErrImagePull'; }
retry 120 denied || die "the private image was pulled anyway"
[ "$(http_out http://192.168.56.200/ web.prod.lab)" = 404 ] || die "web.prod.lab does not 404"
