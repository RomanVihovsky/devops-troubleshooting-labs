# New web node web2 (Rocky 9) fails in the website role
**OPS-320** · P2 · Reporter: platform team

We added our first Rocky 9 web node (`web2`, see `git log`). The `website` role, written for Debian years ago,
fails on it right at the first task. web1 (Debian 12) must keep working.

**Test**: web1 and web2 both serve the ACME home page on port 80 from their OS's Apache; one role for both
(no copy per OS); site.yml converges.
