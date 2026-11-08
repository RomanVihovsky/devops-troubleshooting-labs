# Idempotence check red: 00-base.conf changes on every run; shop accepts 40 MB uploads
**OPS-297** · P2 · Reporter: web team + security

Since the `api` role joined `site.yml`:
* every deploy reports `changed` for *nginx_base : Base config* - twice - and reloads nginx;
* security found that the shop now accepts uploads far above its 1 MB limit (the API needs 50 MB).

**Test**: a second run changes nothing; nginx_base runs once per host; shop.acme.test rejects a 5 MB upload
(413) while api.acme.test accepts it; site.yml converges.
