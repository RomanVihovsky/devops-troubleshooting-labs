# demo is down: "no key could decrypt secret"
**INC-2870** · P1 · Reporter: team demo

While cleaning up `kube-system`, someone deleted "old-looking" Secrets and restarted the Sealed Secrets controller.
Now `demo` has lost its Secret `demo-auth`; the SealedSecret in Git (`workspace/gitops`, app `demo`) can't be
decrypted any more, and `demo.lab` doesn't answer. Re-sealing every secret of every team is not an option - the
plaintext values aren't even known to us. The platform team keeps a DR backup of the sealing key on the desktop:
`.state/sealed-secrets-key.yaml` (treat it like a password).

**Test**: every SealedSecret is Synced again and Secret `demo/demo-auth` exists; `demo.lab` answers 401 without and
200 with its token; Git was not changed (nothing re-sealed); the controller has the original sealing key back.
