# catalog ignores config changes although it re-reads its file
**INC-2433** · P3 · Reporter: team catalog

`catalog` reads `/etc/labapp/app.conf` (`CONFIG_FILE`) on **every request**, so we change its greeting live by
editing the ConfigMap `catalog-files` - no restarts, that's the whole point. Since the "volume cleanup" last
week nothing we change arrives: the ConfigMap says `greeting = Bonjour`, the pods keep saying "Hello".
`workspace/C02/catalog.yaml` is what's deployed.

**Test**: every `catalog` pod answers "Bonjour from ..."; then the test changes the ConfigMap again and every pod
picks the new greeting up **without being restarted or replaced** (within ~2 minutes).
