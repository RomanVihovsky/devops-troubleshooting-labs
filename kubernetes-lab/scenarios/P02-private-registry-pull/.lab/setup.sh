# P02: the image is on the htpasswd registry :5001; the working pull Secret exists - in namespace ci
kns vendor ci
# no cached copy on any node (a cached image would start without credentials)
for w in $(workers); do nx "$w" 'crictl rmi registry.lab:5001/lab/labapp:1.4 >/dev/null 2>&1; true' </dev/null; done
kx -n ci create secret docker-registry regcred --docker-server=registry.lab:5001 --docker-username=ci \
  --docker-password="$(registry_ci_password)" --dry-run=client -o yaml | ka -f -
ka -f vendor-api.yaml
denied() { kx -n vendor get pods -l app=vendor-api -o jsonpath='{.items[*].status.containerStatuses[*].state.waiting.reason}' | grep -qE 'ImagePullBackOff|ErrImagePull'; }
retry 120 denied || die "the private image was pulled anyway"
