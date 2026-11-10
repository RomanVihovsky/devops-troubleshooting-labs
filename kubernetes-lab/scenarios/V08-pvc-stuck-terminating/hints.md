## Hint 1
`kubectl -n forms describe pvc forms-data` - `Finalizers` and "Used By".

## Hint 2
`kubernetes.io/pvc-protection` keeps a claim while any pod still mounts it. Which pod - and is the running
Deployment the same as the file?

## Hint 3
Apply `forms.yaml` (it already mounts `forms-data-v2`): the new pod replaces the old one, the old claim is
released and deleted. Never strip the finalizer while a pod uses the volume.
