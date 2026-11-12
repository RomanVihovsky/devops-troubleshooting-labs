# billing crashloops in the cluster, works on my laptop
**INC-2404** · P2 · Reporter: billing developer

`billing` (`workspace/P04/billing.yaml`, namespace `billing`) starts and dies within a second:
**CrashLoopBackOff**. On my laptop it runs fine with the same image. The manifest was cleaned up last
week ("consistent env var names").

**Test**: billing is Ready and stays up (no new restarts for 60 s); it still requires its database URL
setting (the app's `REQUIRED_ENV` is unchanged).
