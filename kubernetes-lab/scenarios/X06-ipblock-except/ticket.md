# payx can't reach the payment provider
**INC-2580** · P1 · Reporter: team payments

Pods of `payx` (label `app: client`) must call the external payment API at **192.168.56.20:8080**. Since the
egress policy (`workspace/X06/egress.yaml`) went live, those calls time out. Security's rule for this namespace:
**only** the payment API (and DNS) may be reached outside the namespace - nothing else on that network, not even
other ports of the same host.

**Test**: `app: client` pods in `payx` connect to `192.168.56.20:8080`; they can't connect to `192.168.56.20:22`
or `192.168.56.31:22`.
