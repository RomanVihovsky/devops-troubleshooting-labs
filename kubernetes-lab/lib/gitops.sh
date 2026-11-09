# shellcheck shell=bash disable=SC2029,SC2016,SC2034,SC2153
# GitOps + secrets (Phase 2), desktop-driven; credentials live only in .state/ (gitignored):
#   gitops gw     lab CA, OpenBao (TLS, static-key auto-unseal, kv-v2, policy) + Gitea (user lab, repo) on k8s-gw
#   gitops stack  CoreDNS "lab" zone, Sealed Secrets, ESO + ClusterSecretStore "openbao", Argo CD (+ repo secret)
#   gitops seed   push infra/gitops + charts to Gitea lab/gitops (tag baseline), apply the root Application
#   images build  labapp image tags -> registry.lab:5000/lab/labapp (docker on the desktop, crane push on gw)
# SC2029/SC2016: remote commands built on purpose; SC2153/SC2034: names from versions.env / other libs.

CA_DIR="$STATE_DIR/ca"
BAO_DIR="$STATE_DIR/openbao"
GITEA_DIR="$STATE_DIR/gitea"
ARGO_DIR="$STATE_DIR/argocd"
BAO_URL=https://192.168.56.20:8200
GITEA_URL=http://192.168.56.20:3000
GITOPS_REPO=http://git.lab:3000/lab/gitops.git          # the URL Argo CD (in the cluster) uses
SEALED_CERT="$STATE_DIR/sealed-secrets.pem"
SEALED_KEY="$STATE_DIR/sealed-secrets-key.yaml"
LAB_REG=registry.lab:5000

# ------------------------------------------------------------ desktop CLIs ----
gitops_tools() {
  local t
  ensure_tools
  if ! "$BIN_DIR/argocd" version --client --short 2>/dev/null | grep -q "v$ARGOCD_VERSION"; then
    install -m 755 "$(gw_file "argocd-$ARGOCD_VERSION-linux-amd64")" "$BIN_DIR/argocd"
  fi
  if ! "$BIN_DIR/kubeseal" --version 2>/dev/null | grep -q "$SEALED_SECRETS_VERSION"; then
    tar -xzf "$(gw_file "kubeseal-$SEALED_SECRETS_VERSION-linux-amd64.tar.gz")" -C "$BIN_DIR" kubeseal
  fi
  if ! "$BIN_DIR/sops" --version 2>/dev/null | grep -q "$SOPS_VERSION"; then
    install -m 755 "$(gw_file "sops-v$SOPS_VERSION.linux.amd64")" "$BIN_DIR/sops"
  fi
  if ! "$BIN_DIR/age" --version 2>/dev/null | grep -q "$AGE_VERSION"; then
    tar -xzf "$(gw_file "age-v$AGE_VERSION-linux-amd64.tar.gz")" -C "$BIN_DIR" --strip-components=1 age/age age/age-keygen
  fi
  if ! "$BIN_DIR/bao" version 2>/dev/null | grep -q "$OPENBAO_VERSION"; then
    t=$(mktemp -d)
    dpkg-deb -x "$(gw_file "openbao_${OPENBAO_VERSION}_linux_amd64.deb")" "$t"
    install -m 755 "$(find "$t" -type f -name bao | head -1)" "$BIN_DIR/bao"
    rm -rf "$t"
  fi
  [ -s "$STATE_DIR/age.key" ] || "$BIN_DIR/age-keygen" -o "$STATE_DIR/age.key" 2>/dev/null
}

# ------------------------------------------------------------------ lab CA ----
ensure_ca() {
  [ -s "$CA_DIR/ca.crt" ] && return 0
  mkdir -p "$CA_DIR"; chmod 700 "$CA_DIR"
  openssl ecparam -name prime256v1 -genkey -noout -out "$CA_DIR/ca.key"
  openssl req -x509 -new -key "$CA_DIR/ca.key" -sha256 -days 3650 -subj "/CN=kubernetes-lab CA" \
    -addext "basicConstraints=critical,CA:TRUE" -addext "keyUsage=critical,keyCertSign,cRLSign" -out "$CA_DIR/ca.crt"
  ok "lab CA created ($(rel "$CA_DIR")/ca.crt)"
}
# issue_cert <name> <san...>: server cert from the lab CA (kept while valid for > 30 days)
issue_cert() {
  local n=$1 sans; shift; sans=$(IFS=,; echo "$*")
  if [ -s "$CA_DIR/$n.crt" ] && openssl x509 -checkend 2592000 -noout -in "$CA_DIR/$n.crt" >/dev/null; then return 0; fi
  openssl ecparam -name prime256v1 -genkey -noout -out "$CA_DIR/$n.key"
  openssl req -new -key "$CA_DIR/$n.key" -subj "/CN=${1#*:}" -out "$CA_DIR/$n.csr"
  printf 'subjectAltName=%s\nextendedKeyUsage=serverAuth\nkeyUsage=critical,digitalSignature\n' "$sans" > "$CA_DIR/$n.ext"
  openssl x509 -req -in "$CA_DIR/$n.csr" -CA "$CA_DIR/ca.crt" -CAkey "$CA_DIR/ca.key" -CAcreateserial \
    -days 825 -sha256 -extfile "$CA_DIR/$n.ext" -out "$CA_DIR/$n.crt" 2>/dev/null
  rm -f "$CA_DIR/$n.csr" "$CA_DIR/$n.ext"
}

# ------------------------------------------------------------- OpenBao/Gitea ----
# bx <bao args>: the bao CLI against OpenBao on k8s-gw, as root (lab admin)
bx() { BAO_ADDR=$BAO_URL BAO_CACERT=$CA_DIR/ca.crt BAO_TOKEN=$(cat "$BAO_DIR/root-token" 2>/dev/null) "$BIN_DIR/bao" "$@"; }
bao_api() { curl -fsS --max-time 5 --cacert "$CA_DIR/ca.crt" "$BAO_URL/v1/$1" "${@:2}"; }
bao_unsealed() { [ "$(bao_api sys/seal-status 2>/dev/null | jq -r .sealed)" = false ]; }
# gx <path> [curl args]: the Gitea API as user lab
gx() { curl -fsS --max-time 10 -H "Authorization: token $(cat "$GITEA_DIR/token" 2>/dev/null)" -H 'Content-Type: application/json' \
         "$GITEA_URL/api/v1$1" "${@:2}"; }
rand() { openssl rand -hex 16; }

gitops_gw() {
  local init
  if [ "${1:-}" = --reset-openbao ]; then   # only for a fresh/empty OpenBao whose root token got lost
    warn "wiping OpenBao's data on k8s-gw (secrets, auth config, tokens)"
    nx k8s-gw 'systemctl stop openbao; rm -rf /var/lib/openbao/data/*; systemctl reset-failed openbao; systemctl start openbao' </dev/null
    rm -rf "$BAO_DIR"
  fi
  gitops_tools
  ensure_ca
  issue_cert bao DNS:bao.lab IP:192.168.56.20
  info "OpenBao on k8s-gw ($BAO_URL)"
  push_file k8s-gw /etc/openbao/tls/bao.crt 644 < "$CA_DIR/bao.crt"
  push_file k8s-gw /etc/openbao/tls/bao.key 600 < "$CA_DIR/bao.key"
  nx k8s-gw 'chown openbao:openbao /etc/openbao/tls/bao.crt /etc/openbao/tls/bao.key && systemctl restart openbao' </dev/null
  retry 60 bao_api 'sys/health?uninitcode=200&sealedcode=200' || die "OpenBao does not answer on $BAO_URL (journalctl -u openbao on k8s-gw)"
  if [ "$(bao_api sys/init | jq -r .initialized)" = true ] && [ ! -s "$BAO_DIR/root-token" ]; then
    die "OpenBao is initialised but $(rel "$BAO_DIR")/root-token is missing - to start over: ./lab gitops gw --reset-openbao"
  fi
  if [ "$(bao_api sys/init | jq -r .initialized)" != true ]; then
    mkdir -p "$BAO_DIR"; chmod 700 "$BAO_DIR"
    # init (raft bootstrap + keys) takes a while - a client timeout here would lose the one-time root token
    init=$(bao_api sys/init -X PUT --max-time 180 -d '{"recovery_shares":1,"recovery_threshold":1}') || die "OpenBao init failed"
    printf '%s\n' "$init" > "$BAO_DIR/init.json"
    jq -r .root_token <<<"$init" > "$BAO_DIR/root-token"
    chmod 600 "$BAO_DIR/init.json" "$BAO_DIR/root-token"
    ok "OpenBao initialised - recovery key + root token in $(rel "$BAO_DIR")"
  fi
  retry 60 bao_unsealed || die "OpenBao stays sealed - check /etc/openbao/unseal.key and the seal stanza on k8s-gw"
  bx secrets list -format=json | jq -e '."secret/"' >/dev/null || bx secrets enable -path=secret -version=2 kv >/dev/null
  printf '%s\n' 'path "secret/data/*" { capabilities = ["read"] }' 'path "secret/metadata/*" { capabilities = ["read", "list"] }' \
    | bx policy write lab-read - >/dev/null
  bx kv get -mount=secret shop >/dev/null 2>&1 || bx kv put -mount=secret shop \
    postgres_password="$(rand)" redis_password="$(rand)" api_token="$(rand)" >/dev/null
  bx kv get -mount=secret demo >/dev/null 2>&1 || bx kv put -mount=secret demo api_token="$(rand)" >/dev/null
  ok "OpenBao: unsealed (auto), kv-v2 at secret/ (shop, demo), policy lab-read"

  info "Gitea on k8s-gw ($GITEA_URL)"
  mkdir -p "$GITEA_DIR"; chmod 700 "$GITEA_DIR"
  [ -s "$GITEA_DIR/password" ] || { rand > "$GITEA_DIR/password"; chmod 600 "$GITEA_DIR/password"; }
  retry 60 curl -fs --max-time 5 "$GITEA_URL/api/healthz" || die "Gitea does not answer (journalctl -u k8slab-gitea on k8s-gw)"
  nx k8s-gw "g() { runuser -u git -- gitea --config /etc/gitea/app.ini \"\$@\"; }
    g admin user list | awk 'NR > 1 { print \$2 }' | grep -qx lab \
      || g admin user create --admin --username lab --password '$(cat "$GITEA_DIR/password")' --email lab@k8s.lab --must-change-password=false >/dev/null" </dev/null
  if ! gx /user >/dev/null 2>&1; then
    nx k8s-gw "runuser -u git -- gitea --config /etc/gitea/app.ini admin user generate-access-token --username lab \
      --token-name k8slab-$(date +%s) --scopes all --raw" </dev/null > "$GITEA_DIR/token"
    chmod 600 "$GITEA_DIR/token"
  fi
  gx /user >/dev/null || die "Gitea token does not work"
  gx /repos/lab/gitops >/dev/null 2>&1 || gx /user/repos -X POST -d '{"name":"gitops","private":true,"default_branch":"main"}' >/dev/null
  ok "Gitea: user lab, private repo lab/gitops"
}

# ----------------------------------------------------------------- CoreDNS ----
# a "lab" zone in CoreDNS so pods use the real names of the gw services
coredns_lab_zone() {
  local cf
  cf=$(kx -n kube-system get configmap coredns -o jsonpath='{.data.Corefile}')
  grep -q '^lab:53' <<<"$cf" && return 0
  cf+=$'\nlab:53 {\n    errors\n    hosts {\n        192.168.56.20 gw.lab git.lab bao.lab registry.lab k8s-api.lab\n    }\n    cache 30\n}\n'
  kx -n kube-system patch configmap coredns --type merge -p "$(jq -n --arg c "$cf" '{data: {Corefile: $c}}')" >/dev/null
  kx -n kube-system rollout restart deploy/coredns >/dev/null
  kx -n kube-system rollout status deploy/coredns --timeout=3m >/dev/null
  ok "CoreDNS: lab zone (git.lab, bao.lab, registry.lab, k8s-api.lab -> 192.168.56.20)"
}

# ----------------------------------------------------------------- the stack ----
reviewer_token() { [ -n "$(kx -n kube-system get secret openbao-reviewer-token -o jsonpath='{.data.token}' 2>/dev/null)" ]; }
store_ready() { [ "$(kx get clustersecretstore openbao -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)" = True ]; }
gitops_stack() {
  local rj ca
  gitops_tools
  [ -s "$BAO_DIR/root-token" ] || die "OpenBao is not set up yet: ./lab gitops gw"
  coredns_lab_zone

  info "Sealed Secrets $SEALED_SECRETS_VERSION"
  # a backed-up sealing key is restored first, so existing SealedSecrets stay decryptable (the DR story of Y02)
  if [ -s "$SEALED_KEY" ] && ! kx -n kube-system get secret -l sealedsecrets.bitnami.com/sealed-secrets-key -o name | grep -q .; then
    kx apply -f "$SEALED_KEY" >/dev/null && ok "restored the sealing key from $(rel "$SEALED_KEY")"
  fi
  helm_up sealed-secrets kube-system "$(gw_file "sealed-secrets-$SEALED_SECRETS_CHART_VERSION.tgz")" "$ADDONS/sealed-secrets-values.yaml"
  retry 60 "$BIN_DIR/kubeseal" --controller-namespace kube-system --controller-name sealed-secrets-controller --fetch-cert \
    || die "kubeseal cannot fetch the controller cert"
  "$BIN_DIR/kubeseal" --controller-namespace kube-system --controller-name sealed-secrets-controller --fetch-cert > "$SEALED_CERT"
  kx -n kube-system get secret -l sealedsecrets.bitnami.com/sealed-secrets-key -o yaml > "$SEALED_KEY"
  chmod 600 "$SEALED_KEY"

  info "External Secrets Operator $ESO_CHART_VERSION"
  helm_up external-secrets external-secrets "$(gw_file "external-secrets-$ESO_CHART_VERSION.tgz")" "$ADDONS/eso-values.yaml"

  info "OpenBao kubernetes auth (role eso -> SA external-secrets/eso-auth, policy lab-read)"
  kx apply -f "$ADDONS/openbao-auth.yaml" >/dev/null
  retry 60 reviewer_token || die "the openbao-reviewer token was never filled in"
  rj=$(kx -n kube-system get secret openbao-reviewer-token -o jsonpath='{.data.token}' | base64 -d)
  ca=$(mktemp); kx -n kube-system get configmap kube-root-ca.crt -o jsonpath='{.data.ca\.crt}' > "$ca"
  bx auth list -format=json | jq -e '."kubernetes/"' >/dev/null || bx auth enable kubernetes >/dev/null
  bx write auth/kubernetes/config kubernetes_host=https://192.168.56.20:6443 kubernetes_ca_cert=@"$ca" \
    token_reviewer_jwt="$rj" >/dev/null
  rm -f "$ca"
  bx write auth/kubernetes/role/eso bound_service_account_names=eso-auth bound_service_account_namespaces=external-secrets \
    audience=openbao token_policies=lab-read token_ttl=1h >/dev/null
  kx -n external-secrets create configmap lab-ca --from-file=ca.crt="$CA_DIR/ca.crt" --dry-run=client -o yaml | kx apply -f - >/dev/null
  retry 120 kx apply -f "$ADDONS/eso-store.yaml" || die "ClusterSecretStore not accepted (ESO webhook?)"
  retry 120 store_ready || die "ClusterSecretStore openbao not Ready: $(kx get clustersecretstore openbao -o jsonpath='{.status.conditions[0].message}')"
  ok "ClusterSecretStore openbao Ready"

  info "Argo CD $ARGOCD_VERSION (UI http://$ARGOCD_LB_IP)"
  helm_up argocd argocd "$(gw_file "argo-cd-$ARGOCD_CHART_VERSION.tgz")" "$ADDONS/argocd-values.yaml"
  mkdir -p "$ARGO_DIR"; chmod 700 "$ARGO_DIR"
  if kx -n argocd get secret argocd-initial-admin-secret >/dev/null 2>&1; then
    kx -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d > "$ARGO_DIR/admin-password"
    chmod 600 "$ARGO_DIR/admin-password"
  fi
  kx -n argocd create secret generic repo-gitops --from-literal=type=git --from-literal=url="$GITOPS_REPO" \
    --from-literal=username=lab --from-literal=password="$(cat "$GITEA_DIR/token")" --dry-run=client -o yaml \
    | kx label --local -f - argocd.argoproj.io/secret-type=repository -o yaml | kx apply -f - >/dev/null
  ok "Argo CD up; admin password in $(rel "$ARGO_DIR")/admin-password; repo $GITOPS_REPO registered"
}

# ------------------------------------------------------------------ the repo ----
argo_app_ok() { [ "$(kx -n argocd get application "$1" -o jsonpath='{.status.sync.status} {.status.health.status}' 2>/dev/null)" = "Synced Healthy" ]; }
gitops_seed() {
  local w tok ct
  gitops_tools
  [ -s "$SEALED_CERT" ] || die "Sealed Secrets not installed yet: ./lab gitops stack"
  tok=$(cat "$GITEA_DIR/token")
  w=$(mktemp -d)
  cp -r "$LAB_DIR/infra/gitops/." "$w/"
  mkdir -p "$w/charts"; cp -r "$LAB_DIR/charts/labapp" "$LAB_DIR/charts/shop" "$w/charts/"
  rm -f "$w"/charts/shop/charts/*.tgz
  [ -s "$STATE_DIR/demo-token" ] || { rand > "$STATE_DIR/demo-token"; chmod 600 "$STATE_DIR/demo-token"; }
  ct=$(tr -d '\n' < "$STATE_DIR/demo-token" | "$BIN_DIR/kubeseal" --raw --cert "$SEALED_CERT" --scope strict \
        --namespace demo --name demo-auth --from-file=/dev/stdin)
  sed -i "s|@DEMO_AUTH_TOKEN_SEALED@|$ct|" "$w/envs/demo/values.yaml"
  sed -i "s|@AGE_RECIPIENT@|$(sed -n 's/^# public key: //p' "$STATE_DIR/age.key")|" "$w/.sops.yaml"
  info "pushing the baseline to Gitea lab/gitops (tag baseline)"
  git -C "$w" init -q -b main
  git -C "$w" add -A
  git -C "$w" -c user.name=lab -c user.email=lab@k8s.lab commit -qm "lab baseline"
  git -C "$w" tag -f baseline >/dev/null
  if ! git -C "$w" push -q --force "http://lab:$tok@192.168.56.20:3000/lab/gitops.git" main baseline 2>"$w.err"; then
    cat "$w.err" >&2; rm -rf "$w" "$w.err"; die "push to Gitea failed"
  fi
  rm -f "$w.err"
  rm -rf "$w"
  kx apply -f "$LAB_DIR/infra/gitops/bootstrap/root.yaml" >/dev/null
  kx -n argocd annotate application lab-apps argocd.argoproj.io/refresh=hard --overwrite >/dev/null
  retry 300 argo_app_ok lab-apps || warn "lab-apps not Synced/Healthy yet"
  retry 300 argo_app_ok demo || warn "demo not Synced/Healthy yet"
  retry 300 argo_app_ok shop || warn "shop not Synced/Healthy yet"
  ok "seeded: $(kx -n argocd get applications -o jsonpath='{range .items[*]}{.metadata.name}={.status.sync.status}/{.status.health.status} {end}')"
}

# gitops_clone: the student's working copy (credentials stay in .state, not in the workspace)
gitops_clone() {
  local ws="$LAB_DIR/workspace/gitops" cred="$GITEA_DIR/git-credentials"
  printf 'http://lab:%s@192.168.56.20%%3a3000\n' "$(cat "$GITEA_DIR/token")" > "$cred"; chmod 600 "$cred"
  [ -d "$ws/.git" ] && rm -rf "$ws"
  mkdir -p "$(dirname "$ws")"
  git -c credential.helper="store --file=$cred" clone -q "$GITEA_URL/lab/gitops.git" "$ws"
  git -C "$ws" config credential.helper "store --file=$cred"
  git -C "$ws" config user.name student; git -C "$ws" config user.email student@k8s.lab
  ok "workspace/gitops: clone of lab/gitops (push here, Argo CD syncs within a minute)"
}

# ------------------------------------------------------------------ images ----
images_build() {
  local t
  command -v docker >/dev/null || die "docker is needed on this desktop to build labapp"
  info "building labapp ($LABAPP_TAGS) with apps/labapp/build.sh"
  bash "$LAB_DIR/apps/labapp/build.sh" "$LAB_REG/lab" >/dev/null || die "labapp build failed"
  for t in $LABAPP_TAGS; do
    docker save "$LAB_REG/lab/labapp:$t" | push_file k8s-gw /var/tmp/labapp.tar 644
    nx k8s-gw "crane push --insecure /var/tmp/labapp.tar $LAB_REG/lab/labapp:$t >/dev/null 2>&1; rc=\$?; rm -f /var/tmp/labapp.tar; exit \$rc" </dev/null \
      || die "crane push labapp:$t failed"
    echo "  $LAB_REG/lab/labapp:$t"
  done
  ok "labapp images in the lab registry"
}

# ---------------------------------------------------------------- doctor ----
demo_auth_ok() {
  local h=(-H 'Host: demo.lab') u=http://192.168.56.200/
  [ "$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 "${h[@]}" "$u")" = 401 ] \
    && [ "$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 "${h[@]}" -H "Authorization: Bearer $(cat "$STATE_DIR/demo-token")" "$u")" = 200 ]
}
shop_ok() { curl -fs --max-time 8 -H 'Host: shop.lab' http://192.168.56.200/upstream | jq -e '.status == 200 and (.body | test("items"))' >/dev/null; }
es_ready() { [ "$(kx -n "$1" get externalsecret "$2" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)" = True ]; }
gitops_checks() {
  local a
  if ! kx get namespace argocd >/dev/null 2>&1; then echo "  - GitOps & secrets: not installed (./lab gitops gw|stack|seed)"; return 0; fi
  echo "  ${C_BOLD}GitOps & secrets${C_0}"
  check "Gitea API ($GITEA_URL) and repo lab/gitops at tag baseline" gx /repos/lab/gitops/tags/baseline
  check "OpenBao unsealed (TLS with the lab CA)" bao_unsealed
  check "OpenBao kv secret/shop readable" bx kv get -mount=secret shop
  check_eventually 60 "ClusterSecretStore openbao Ready" store_ready
  check_eventually 120 "ExternalSecret shop/shop-secrets Ready (OpenBao -> Secret)" es_ready shop shop-secrets
  check_eventually 60 "SealedSecret demo/demo-auth decrypted to a Secret" kx -n demo get secret demo-auth
  for a in lab-apps demo shop; do check_eventually 180 "Argo CD app $a Synced + Healthy" argo_app_ok "$a"; done
  check_eventually 90 "shop.lab end to end (frontend -> api -> postgres + redis, Bearer token)" shop_ok
  check_eventually 60 "demo.lab: 401 without token, 200 with the sealed one" demo_auth_ok
  check "Argo CD UI http://$ARGOCD_LB_IP" curl -fs --max-time 5 "http://$ARGOCD_LB_IP/healthz"
}
