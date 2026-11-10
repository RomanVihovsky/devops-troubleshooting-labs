# uploads: volume never provisioned
**INC-2701** · P3 · Reporter: uploads team

`uploads` (namespace `uploads`, `workspace/V01/uploads.yaml`) was copied from the cloud cluster. Its PVC
stays **Pending** and the pod never starts. Any StorageClass of this cluster is fine.

**Test**: the PVC `uploads-data` is Bound and the uploads pod runs.
