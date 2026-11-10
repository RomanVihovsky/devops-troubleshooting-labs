kx patch pv orders-archive --type json -p '[{"op":"remove","path":"/spec/claimRef"}]' >/dev/null
kx -n archive wait --for=condition=Ready pod/reader --timeout=120s >/dev/null
