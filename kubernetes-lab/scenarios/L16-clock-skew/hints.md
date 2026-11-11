## Hint 1
`./lab node w1`, `date -u`, and compare with the desktop's `date -u`. "Not yet valid" is the other half of that
x509 message: `openssl x509 -noout -dates -in /var/lib/kubelet/pki/kubelet-client-current.pem`.

## Hint 2
`systemctl status chrony` and `chronyc tracking`. Something stopped the time sync and set the clock by hand.

## Hint 3
`sudo systemctl enable --now chrony`, then `sudo chronyc makestep` (the lab's chrony steps any offset > 1 s:
`makestep 1 -1`). Give the kubelet a minute to reconnect - no certificate needs to change.
