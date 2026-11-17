# Deployments to orders fail: "failed calling webhook"
**INC-2702** · P1 · Reporter: team orders

Since this morning every create or update in namespace `orders` is refused:
*Internal error occurred: failed calling webhook "pods.policy.lab": ... no endpoints available for service
"pod-policy"*. The pod policy webhook (`workspace/A09/pod-policy.yaml`, namespace `policy-system`) was redeployed
yesterday "with health checks". Security insists the policy stays enforced: it must keep failing closed
(`failurePolicy: Fail`) and keep covering `orders`.

**Test**: creating objects in `orders` works again; the webhook still enforces its policy in `orders` (an object
labelled `policy.lab/deny=true` is rejected by it); `ValidatingWebhookConfiguration pod-policy` still fails
closed.
