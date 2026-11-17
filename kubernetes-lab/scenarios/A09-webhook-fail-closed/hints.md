## Hint 1
The error names the Service: `kubectl -n policy-system get endpointslices,pods -o wide`. Why does the Service
have no ready endpoints although the pod is Running?

## Hint 2
`kubectl -n policy-system describe pod -l app=pod-policy` - the readiness probe fails. The webhook only speaks
**HTTPS** (the API server calls nothing else); what scheme does the probe use?

## Hint 3
Add `scheme: HTTPS` to the readinessProbe's `httpGet` (the kubelet doesn't verify the certificate), apply, wait
for the pod to become Ready. Don't touch `failurePolicy`.
