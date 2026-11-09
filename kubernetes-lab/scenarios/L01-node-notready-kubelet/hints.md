## Hint 1
`kubectl describe node k8s-w2` - look at the Conditions: *"Kubelet stopped posting node status"*. Who posts
the node status?

## Hint 2
On the node: `systemctl status kubelet` and `journalctl -u kubelet -n 20`. Is it crashing - or just not
running at all?

## Hint 3
kubelet was stopped **and disabled**: `sudo systemctl enable --now kubelet`. "enable" is what makes it
survive the next reboot - the ticket's Test asks for both.
