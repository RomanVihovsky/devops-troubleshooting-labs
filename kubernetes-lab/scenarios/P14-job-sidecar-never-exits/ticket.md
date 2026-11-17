# The nightly report never finishes
**INC-2611** · P3 · Reporter: team finance

Since we added log shipping to `nightly-report` (`workspace/P14/nightly-report.yaml`), the Job never completes.
The report itself is written - its log says *report complete* within a few seconds - but the Job stays *Running*
forever, so the morning pipeline that waits for it never starts. We need the log shipping: the run log must
still reach the cluster logs.

**Test**: Job `nightly-report` in `reports` is Complete; the report container still writes its log file; a log
shipper still runs in the Job's pod and its output contains *report complete*.
