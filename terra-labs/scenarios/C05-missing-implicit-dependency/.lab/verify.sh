d=stacks/worker
ordered() {
  ci_init $d && ci_tf $d graph -type=plan 2>>"$VERIFY_LOG" > "$CI/graph.dot" &&
    grep -E 'docker_container\.worker[^"]*" -> "(\[root\] )?docker_network\.jobs' "$CI/graph.dot" >/dev/null
}
same_all() { for w in mail pdf thumbs; do same_ctr "tfl-worker-$w" || return 1; done; }
check "graph: workers depend on the network" ordered
check "existing worker containers not recreated" same_all
check "CI plan of stacks/worker shows no changes" plan_clean $d
verdict
