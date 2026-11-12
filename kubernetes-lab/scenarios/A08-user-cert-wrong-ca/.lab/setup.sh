# A08: alice's client cert was signed by a "team CA" the API server doesn't trust
kns dev
kx -n dev create rolebinding alice-view --clusterrole=view --user=alice --dry-run=client -o yaml | ka -f -
kx -n dev create deployment hello --image=registry.lab:5000/lab/labapp:1.4 --dry-run=client -o yaml | ka -f -
d=$(mktemp -d)
openssl genrsa -out alice.key 2048 2>/dev/null
openssl req -x509 -new -nodes -newkey rsa:2048 -keyout "$d/ca.key" -subj "/CN=team-ca" -days 365 -out "$d/ca.crt" 2>/dev/null
openssl req -new -key alice.key -subj "/CN=alice/O=dev-team" -out "$d/alice.csr"
openssl x509 -req -in "$d/alice.csr" -CA "$d/ca.crt" -CAkey "$d/ca.key" -CAcreateserial -days 365 -out alice.crt 2>/dev/null
remember a08_key "$(openssl pkey -in alice.key -pubout | sha256sum | cut -d' ' -f1)"
kx config view --minify --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}' | base64 -d > "$d/cluster-ca.crt"
server=$(kx config view --minify -o jsonpath='{.clusters[0].cluster.server}')
export KUBECONFIG=$PWD/kubeconfig
kubectl config set-cluster lab --server="$server" --certificate-authority="$d/cluster-ca.crt" --embed-certs >/dev/null
kubectl config set-credentials alice --client-certificate=alice.crt --client-key=alice.key --embed-certs >/dev/null
kubectl config set-context alice@lab --cluster=lab --user=alice --namespace=dev >/dev/null
kubectl config use-context alice@lab >/dev/null
rm -rf "$d"
! kubectl -n dev get pods >/dev/null 2>&1 || die "alice's kubeconfig works"
