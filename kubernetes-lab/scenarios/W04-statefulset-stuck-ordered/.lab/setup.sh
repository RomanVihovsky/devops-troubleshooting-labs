# W04: readiness on a path that doesn't exist - OrderedReady never gets past quorum-0
kns quorum
ka -f quorum.yaml
stuck() { kx -n quorum get pod quorum-0 >/dev/null 2>&1 && ! kx -n quorum get pod quorum-1 >/dev/null 2>&1 \
          && [ "$(kx -n quorum get pod quorum-0 -o jsonpath='{.status.phase}')" = Running ]; }
retry 120 stuck || die "quorum is not stuck at quorum-0"
sleep 10; stuck || die "quorum-1 appeared"
