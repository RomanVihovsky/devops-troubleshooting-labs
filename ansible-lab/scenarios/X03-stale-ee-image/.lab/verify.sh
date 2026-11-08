tag=$(tr -d '[:space:]' < "$CI/ci/ee-image" 2>/dev/null)
echo "ci/ee-image: $tag" >> "$VERIFY_LOG"
ee_ok() {
  [ -n "$tag" ] && [ "$tag" != acme/ee:1 ] && docker image inspect "$tag" >/dev/null 2>&1 &&
    docker run --rm "$tag" ansible --version 2>>"$VERIFY_LOG" | head -1 | grep -q 'core 2.22.0' &&
    docker run --rm "$tag" python3 -c 'import jmespath' 2>>"$VERIFY_LOG"
}
ee_converges() {
  docker run --rm --network "$NET" --user "$(id -u):0" -v "$CI:/runner/project" -v "$SSH_DIR:/runner/.ssh:ro" \
    -w /runner/project -e ANSIBLE_STDOUT_CALLBACK=ansible.posix.json "$tag" \
    ansible-playbook site.yml --check > "$CI/.lab-ap.raw" 2>>"$VERIFY_LOG"
  sed -n '/^{$/,/^}$/p' "$CI/.lab-ap.raw" > "$CI/.lab-ap.json"
  stats_ok '.changed == 0 and .failures == 0 and .unreachable == 0'
}
check "ci/ee-image names a new tag with ansible-core 2.22.0 + jmespath" ee_ok
check "site.yml converges inside that EE" ee_converges
check "acme/ee:1 is unchanged (immutable tag)" eval '[ "$(docker image inspect -f "{{.Id}}" acme/ee:1 2>/dev/null)" = "$(recall ee1_id)" ]'
check "web1 lists the public services: shop,api" eval '[ "$(nx web1 "cat /etc/acme/services.txt" 2>/dev/null)" = "shop,api" ]'
verdict
