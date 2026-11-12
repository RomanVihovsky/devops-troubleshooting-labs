# The nightly report job fails
**INC-2490** · P3 · Reporter: finance

`nightly-report` (namespace `batch`, `workspace/W07/report.yaml`) shows *Failed: BackoffLimitExceeded*. The report
script itself is fine - it's in the ConfigMap `report-script` and nobody touched it.

**Test**: a Job `nightly-report` has Completed and its log contains "report done"; the script still comes
from ConfigMap `report-script` (unchanged).
