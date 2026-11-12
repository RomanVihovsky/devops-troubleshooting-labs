# notifier deployed, but no pods appear
**INC-2532** · P4 · Reporter: team sandbox

We added `notifier` to namespace `sandbox` next to `legacy` (2 pods). `notifier` shows 0/1 and has no pods at all.
The namespace's quota was set by the platform team; per ticket PLAT-411 they approved raising **pods to 5** - no
other change to the quota.

**Test**: `notifier` has 1 Ready pod; `legacy` still has 2; the ResourceQuota allows exactly 5 pods and is
otherwise unchanged.
