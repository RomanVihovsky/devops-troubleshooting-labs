## Hint 1
Who answers on 192.168.56.20:6443? `./lab node gw`, `sudo ss -tlnp | grep 6443`. haproxy's stats page:
`curl -s 'http://192.168.56.20:8404/;csv' | cut -d, -f1,2,18`.

## Hint 2
`sudo grep -n server /etc/haproxy/haproxy.cfg` - which address does the backend point to? Is there a VM there?

## Hint 3
Point `server k8s-cp1` back to `192.168.56.21:6443`, check with `sudo haproxy -c -f /etc/haproxy/haproxy.cfg`,
then `sudo systemctl reload haproxy`. The kubelets reconnect by themselves.
