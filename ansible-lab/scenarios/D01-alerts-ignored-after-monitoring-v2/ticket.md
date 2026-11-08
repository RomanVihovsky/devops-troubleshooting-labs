# Monitoring 2.0: nginx alerts reach EDA (HTTP 200) - nothing gets fixed
**OPS-3127** · P2 · Reporter: on-call (night shift)

nginx on **web3** died at 03:12. Monitoring alerted, the EDA activation answered the webhook with **HTTP 200**
(it's in the activation log) - and nothing happened. I restarted nginx by hand at 07:40; it died again at 09:05
(same story, it is down right now). Before Tuesday the self-healing worked fine: last month it brought web1 back
three times. The only change I know of: the monitoring team cut over to **Monitoring 2.0** on Tuesday - their
payload samples are in `docs/alerts/`.

Monitoring will not go back to the v1 format. Make the self-healing work for v2 alerts - for the host in the
alert only - and get web3 healed the way it should be.

**Test**: the activation (from a CI checkout) heals a stopped nginx on web3 within 60 s of a v2 `critical` alert for
`web3.acme.internal`; web1 is not touched; a v2 `ok` alert runs nothing; site.yml converges.
