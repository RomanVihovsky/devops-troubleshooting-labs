## Hint 1
No pod means the kubelet never created it: the static pod comes from a file. `./lab node cp1`, then
`sudo journalctl -u kubelet --since -10min | grep -i scheduler`.

## Hint 2
The kubelet skips a manifest it can't parse (and removes its pod). `sudo cat -A
/etc/kubernetes/manifests/kube-scheduler.yaml | grep -n v=2` - look at the indentation characters.

## Hint 3
YAML indentation must be spaces; a tab is not allowed. Fix the line (same indent as the other flags), save it
outside `manifests/` and move it back. `python3 -c 'import yaml,sys; yaml.safe_load(open(sys.argv[1]))' file`
checks it.
