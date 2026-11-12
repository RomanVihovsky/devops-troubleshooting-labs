# shop down: api and frontend pods can't start
**INC-2266** · P1 · Reporter: on-call

After dev-bob's "secret path cleanup" in `envs/shop`, someone deleted `shop-secrets` to "force a refresh"
and restarted the pods. Now `shop.lab` is down: the new api and frontend pods don't start. The values in
OpenBao (`secret/shop`) are correct and must stay where they are - don't copy secrets around.

**Test**: ExternalSecret `shop/shop-secrets` is Ready and the Secret has its 3 keys; shop.lab works end to
end; the fix is in Git (`envs/shop/values.yaml`); OpenBao still has the secret only at `secret/shop`.
