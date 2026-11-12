# W02: v1 is deployed; v2 changes the Deployment's selector, which is immutable
kns search
ka -f search.yaml
wait_rollout search deploy/search
! kx apply -f search-v2.yaml >/dev/null 2>&1 || die "the selector change was accepted"
rm -f search.yaml
