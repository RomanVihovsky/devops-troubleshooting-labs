## Hint 1
`kubectl -n reports describe pod <pod>` - what did the runtime try to execute?

## Hint 2
`command:` in a pod spec replaces the image's ENTRYPOINT (`args:` replaces CMD). What does the image
start by default? (`crane config` / the Dockerfile in `apps/labapp`).

## Hint 3
Remove the `command:` override from `reports.yaml` - the image's own entrypoint is the server. Apply.
