# Some requests to edge fail - which ones?
**INC-2541** · P3 · Reporter: customer support

Customers report occasional errors from `edge` (6 pods in namespace `edge`). Most pages work. We need the failing
**path** and the error message the app logs for it, from the logs of all 6 pods (`stern` is on your PATH after
`eval "$(./lab env)"`). Write them into `workspace/Q05/answers.yaml`.

**Test**: the path that fails and (part of) the error message the app logs for it.
