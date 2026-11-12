# G05: the team Gateway only admits routes from its own namespace; shop's route lives in gw-shop
kns gw-infra gw-shop gw-other
ka -f gateway.yaml
backend() { kx create deployment "$2" -n "$1" --image=registry.lab:5000/lab/labapp:1.4 --dry-run=client -o yaml | ka -f -
            kx -n "$1" create service clusterip "$2" --tcp=8080:8080 --dry-run=client -o yaml | ka -f -; }
backend gw-shop shop; backend gw-other other
ka -f route.yaml
sed 's/name: shop, namespace: gw-shop/name: other, namespace: gw-other/; s/shop.team.lab/other.team.lab/; s/name: shop, port/name: other, port/' route.yaml | ka -f -
refused() { kx -n gw-shop get httproute shop -o jsonpath='{.status.parents[*].conditions[?(@.type=="Accepted")].reason}' | grep -q NotAllowedByListeners; }
retry 90 refused || die "the route is not refused"
