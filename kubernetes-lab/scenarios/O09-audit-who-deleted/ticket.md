# checkout's feature flags vanished
**INC-2809** · P2 · Reporter: team checkout

ConfigMap `feature-flags` in namespace `checkout` was deleted a few minutes ago - `checkout` restarted with every
flag off. It isn't managed by Argo CD or Helm, nobody admits it, and several people and bots have access. API server
auditing is on (`k8s-cp1`). Find who deleted it, when, and with which tool, and write it into
`workspace/O09/answers.yaml`. Then put the ConfigMap back from `workspace/O09/feature-flags.yaml`.

**Test**: the answers name the user who deleted `checkout/feature-flags`, the minute it happened (UTC) and the
client they used; `feature-flags` exists again with its flags.
