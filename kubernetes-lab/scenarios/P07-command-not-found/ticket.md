# reports: RunContainerError since the "production server" change
**INC-2407** · P2 · Reporter: reports team

We switched `reports` (namespace `reports`, `workspace/P07/reports.yaml`) to "a proper production server
like the other Python services". Now the pods show **RunContainerError**: `exec: "gunicorn": executable
file not found in $PATH`. Same image as before.

**Test**: reports is Ready (its readiness probe passes) on the same image.
