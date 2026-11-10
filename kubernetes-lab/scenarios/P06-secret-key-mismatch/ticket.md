# ledger pods stuck in CreateContainerConfigError
**INC-2406** · P2 · Reporter: ledger team

After the DB password rotation the new `ledger` pods (namespace `ledger`, `workspace/P06/ledger.yaml`)
never start: **CreateContainerConfigError**. The Secret `ledger-db` was rotated by the DBA team - its value
is correct and must not change.

**Test**: ledger is Ready; the Secret `ledger-db` still holds the DBA's value.
