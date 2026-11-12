# old-team won't go away
**INC-2586** · P4 · Reporter: platform team

We deleted namespace `old-team` (team dissolved) days ago; it's still *Terminating*. The team used the backup
operator, which was uninstalled last month - its CRD `backups.example.com` stays (other teams' Backup objects
still exist). Make the namespace go away the right way: no force-finalizing of the namespace itself.

**Test**: namespace `old-team` is gone; the CRD `backups.example.com` still exists, and `team-z`'s Backup is still
there.
