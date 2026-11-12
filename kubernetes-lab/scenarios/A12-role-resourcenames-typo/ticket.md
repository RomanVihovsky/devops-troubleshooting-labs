# payroll: secret-sync job fails every night
**INC-2271** · P3 · Reporter: payroll team

The Job `secret-sync` in `payroll` fails: `secrets "db-creds" is forbidden: User
"system:serviceaccount:payroll:syncer" cannot get resource "secrets"`. But the `app` pods mount `db-creds`
without trouble, and the RBAC was "copied from the docs". The manifests are in `workspace/A12/`. Security's
rule: the job may read **that one Secret** and nothing else. Re-run the job when it's fixed.

**Test**: Job `secret-sync` completes; the SA `syncer` can get `db-creds` but not list secrets nor get any
other Secret (`payroll-bank`), in `payroll` or anywhere else.
