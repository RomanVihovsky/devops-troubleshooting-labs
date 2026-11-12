gone() { ! kx get ns old-team >/dev/null 2>&1; }
check_eventually 60 "namespace old-team is gone" gone
check "CRD backups.example.com still exists" kx get crd backups.example.com
check "team-z's Backup is still there" kx -n team-z get backup nightly
verdict
