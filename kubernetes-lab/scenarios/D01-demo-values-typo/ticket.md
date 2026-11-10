# demo release "1.4 + Bonjour" never arrived
**INC-2231** · P3 · Reporter: product owner, French market

Yesterday dev-bob merged the demo release for the French launch: the current labapp image and the greeting
**Bonjour**. Argo CD says *Synced*, but the app shows a spinning *Progressing*, the pods look odd, and
`demo.lab` still greets with **Hello**. Git (`workspace/gitops`) is the source of truth - fix it there.

**Test**: demo is Synced and Healthy with every pod on an image tag that exists in `registry.lab:5000`,
`demo.lab` answers "Bonjour ..." (with the Bearer token), and the fix is in Git (`envs/demo/values.yaml`).
