# invoices crashloops after the hardening
**INC-2806** · P2 · Reporter: invoices team

Security hardened `invoices` (namespace `invoices`, `workspace/A06/invoices.yaml`) with a read-only root
filesystem. Now it crashes at start: *Read-only file system*. The read-only rootfs stays.

**Test**: invoices is Ready and stays up (no new restarts for 60 s), with `readOnlyRootFilesystem: true`.
