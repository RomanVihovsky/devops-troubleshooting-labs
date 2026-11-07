# Every apply "changes" the db security group - reporting loses DB access every other run
**INFRA-195** · P2 · Reporter: data team

The reporting jobs lose access to the database after every other run of the `stacks/db` pipeline,
and get it back on the next one. The plan is never clean: it always shows `~ aws_security_group.db`
or `+ aws_security_group_rule.reporting`. The app rule and the reporting rule must both stay.

Make it converge. The security group itself must not be replaced (ENIs are attached to it).

**Test**: both rules (app `10.50.1.0/24` and reporting `10.60.0.0/16`, port 5432) exist; two consecutive
CI plans show no changes; it is still the same security group.
