mf() { kx -n inventory get deploy inventory-api -o json --show-managed-fields 2>/dev/null; }
debug() { [ "$(kx -n inventory get deploy inventory-api -o jsonpath='{.spec.template.spec.containers[0].env[?(@.name=="LOG_LEVEL")].value}' 2>/dev/null)" = debug ]; }
pipeline_owns() {
  mf | jq -e '[.metadata.managedFields[] | select(.manager == "pipeline-inventory" and .operation == "Apply")
    | .fieldsV1["f:spec"]["f:template"]["f:spec"]["f:containers"]["k:{\"name\":\"api\"}"]["f:env"]["k:{\"name\":\"LOG_LEVEL\"}"]["f:value"]
    | select(. != null)] | length > 0' >/dev/null
}
# ops-hotfix may keep co-owning the list item's identity (f:name) - SSA does that - but no env value
hotfix_gone() {
  mf | jq -e '[.metadata.managedFields[] | select(.manager == "ops-hotfix")
    | .fieldsV1["f:spec"]["f:template"]["f:spec"]["f:containers"]["k:{\"name\":\"api\"}"]["f:env"] // {}
    | to_entries[] | select(.value | type == "object" and has("f:value"))] | length == 0' >/dev/null
}
clean_apply() { kx apply --server-side --field-manager=pipeline-inventory --dry-run=server -f "$STATE_DIR/scenario.o10-intended.yaml" >/dev/null 2>&1; }
check "inventory-api runs with LOG_LEVEL=debug" debug
check "pipeline-inventory owns env LOG_LEVEL's value" pipeline_owns
check "ops-hotfix owns no env value any more" hotfix_gone
check "the pipeline's apply (no --force-conflicts) goes through" clean_apply
check_eventually 120 "inventory-api: 2 Ready pods" deploy_ready inventory inventory-api 2
verdict
