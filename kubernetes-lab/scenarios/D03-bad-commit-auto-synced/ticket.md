# demo.lab down since the 2.0 release candidate
**INC-2240** · P1 · Reporter: on-call

`demo.lab` answers **503** for everyone. Argo CD shows demo *Synced* - it deployed exactly what is on `main`
(auto-sync). The release candidate went in ten minutes ago. Roll back the right way: the team wants the
history intact, auto-sync stays on, and the RC should be easy to re-apply once it's fixed.

**Test**: demo.lab answers 200 again (with the Bearer token); demo is Synced and Healthy; `main` no longer
deploys `2.0.0-rc1` but still contains the RC commit (history not rewritten); automated sync with self-heal
is still on for demo.
