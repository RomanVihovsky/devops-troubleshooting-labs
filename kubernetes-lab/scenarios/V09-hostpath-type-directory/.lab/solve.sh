sed -i 's/type: Directory}/type: DirectoryOrCreate}/' spool-agent.yaml
kx apply -f spool-agent.yaml >/dev/null
kx -n agent rollout status ds/spool-agent --timeout=180s >/dev/null
