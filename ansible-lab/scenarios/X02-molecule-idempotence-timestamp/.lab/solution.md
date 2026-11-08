# Solution - no timestamps in managed files

**Root cause**: the template embeds `ansible_facts['date_time']['iso8601']`. Every run renders a different file,
so the template task is (correctly) `changed` every time - molecule's idempotence step catches it.

**Fix**: remove the timestamp. If "last deployed" matters, log it (callback, CMDB API) or look at the mtime.

**Interview notes**
* Other classic sources: `ansible_managed` strings with dates (older configs), random ordering of dict/set
  output (`| dictsort`), `lookup('pipe', 'date')`, generated passwords without a seed.
* Never "fix" idempotence with `changed_when: false` on a task that writes - drift goes unnoticed.
* Molecule sequence here: syntax -> converge -> idempotence -> verify (delegated driver against test1).
