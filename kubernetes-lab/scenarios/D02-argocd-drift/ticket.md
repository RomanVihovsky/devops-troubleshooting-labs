# demo has been OutOfSync in Argo CD since yesterday
**INC-2214** · P3 · Reporter: release manager

Argo CD (http://192.168.56.201) shows the **demo** app *OutOfSync* since yesterday. The cluster runs
**5** demo pods - Git says 2 - and someone set a greeting by hand during an incident. Self-heal is off on
purpose: the change freeze (INC-2210) is in Git and stays until the Q4 release. Git is the source of truth.
Your clone: `workspace/gitops`.

**Test**: demo is Synced and Healthy and runs exactly what Git declares; the freeze (self-heal off) is
still in Git, and Git's history wasn't rewritten.
