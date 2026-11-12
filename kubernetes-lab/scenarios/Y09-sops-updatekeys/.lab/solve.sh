W="$LAB_DIR/workspace/gitops"
git -C "$W" pull -q
(cd "$W" && SOPS_AGE_KEY_FILE="$STATE_DIR/age.key" "$BIN_DIR/sops" updatekeys -y secrets/prod.enc.yaml >/dev/null 2>&1)
git -C "$W" commit -qam "secrets: re-wrap prod.enc.yaml for alice (sops updatekeys) (INC-2377)"
git -C "$W" push -q origin main 2>/dev/null
