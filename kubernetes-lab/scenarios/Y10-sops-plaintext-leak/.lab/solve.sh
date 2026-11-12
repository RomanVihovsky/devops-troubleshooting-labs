W="$LAB_DIR/workspace/gitops"; export SOPS_AGE_KEY_FILE="$STATE_DIR/age.key"
git -C "$W" pull -q
sed -i -E 's/^(\s*encrypted_regex: ).*/\1^(data|stringData)$/' "$W/.sops.yaml"
new="r-$(openssl rand -hex 10)"
printf 'apiVersion: v1\nkind: Secret\nmetadata:\n  name: redis-auth\n  namespace: newsvc\ntype: Opaque\nstringData:\n  password: %s\n' "$new" > "$W/secrets/new-service.enc.yaml"
(cd "$W" && "$BIN_DIR/sops" -e -i secrets/new-service.enc.yaml)
git -C "$W" commit -qam "secrets: encrypt stringData too; rotate the leaked redis password (SEC-118)"
git -C "$W" push -q origin main 2>/dev/null
"$BIN_DIR/sops" -d "$W/secrets/new-service.enc.yaml" | kx apply -f - >/dev/null
kx -n newsvc rollout restart deploy/redis >/dev/null
wait_rollout newsvc deploy/redis || true
