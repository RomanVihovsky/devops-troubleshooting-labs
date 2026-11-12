# ml-api never schedules, not even an error
**INC-2507** · P3 · Reporter: ML team

Our `ml-api` (namespace `ml`, `workspace/S07/ml-api.yaml`) - copied from the old GPU cluster's repo - stays
**Pending**, and `kubectl describe pod` shows **no events at all**. Every other app in the cluster schedules
fine.

**Test**: ml-api runs and is Ready, scheduled by the cluster's scheduler.
