# reporter deployed, but no pods
**INC-2607** · P3 · Reporter: team reporter

`reporter` (`workspace/A04/reporter.yaml`) in `secure-apps` shows 0/2 and there are no pods to look at. The
namespace enforces the **restricted** Pod Security Standard (company policy - it stays). The app doesn't need
any privileges; the manifest was copied from an old cluster.

**Test**: `reporter` has 2 Ready pods; `secure-apps` still enforces `restricted`.
