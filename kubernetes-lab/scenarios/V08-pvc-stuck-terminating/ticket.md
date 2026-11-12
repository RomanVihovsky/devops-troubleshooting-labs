# old forms volume won't go away
**INC-2708** · P3 · Reporter: forms team

We migrated `forms` to the new volume `forms-data-v2` and deleted the old claim `forms-data`. That was an
hour ago: `forms-data` still shows **Terminating**. The manifest `workspace/V08/forms.yaml` was "already
updated" - we think.

**Test**: `forms-data` is gone; forms runs (Ready) on `forms-data-v2`.
