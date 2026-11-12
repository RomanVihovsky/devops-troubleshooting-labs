kx patch clusterrolebinding secret-reader --type json -p '[{"op":"replace","path":"/subjects","value":[{"kind":"ServiceAccount","name":"backup-agent","namespace":"backup"}]}]' >/dev/null
