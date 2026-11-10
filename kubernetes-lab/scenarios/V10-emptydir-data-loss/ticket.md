# notes: everything we save disappears after a redeploy
**INC-2710** · P2 · Reporter: notes team

`notes` (namespace `notes`, `workspace/V10/notes.yaml`) keeps its data in `/data`. Every time the pod is
recreated (deploy, node drain), all notes are gone. One replica is fine.

**Test**: a file written to `/data` survives deleting the pod (verify writes one, deletes the pod and
reads it back from the new pod).
