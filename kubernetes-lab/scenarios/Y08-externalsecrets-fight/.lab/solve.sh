W="$LAB_DIR/workspace/gitops"
git -C "$W" pull -q
git -C "$W" rm -q envs/partners/api-key-legacy.yaml
sed -i 's/creationPolicy: Merge/creationPolicy: Owner/' "$W/envs/partners/api-key.yaml"
git -C "$W" commit -qam "partners: one writer for api-key - drop the legacy ExternalSecret (INC-2741)"
git -C "$W" push -q origin main 2>/dev/null
argo_refresh partners
gone() { ! kx -n partners get externalsecret api-key-legacy >/dev/null 2>&1; }
retry 180 gone || true
# ESO takes over a hand-made Secret only if it may: re-create it as the ExternalSecret's own
kx -n partners delete secret api-key --ignore-not-found >/dev/null
kx -n partners annotate externalsecret api-key force-sync="$(date +%s)" --overwrite >/dev/null
owned() { [ "$(kx -n partners get secret api-key -o jsonpath='{.metadata.ownerReferences[0].name}' 2>/dev/null)" = api-key ]; }
retry 120 owned || true
