# X09: the student's allow policies are not labelled; the baseline has no NetworkPolicies in these namespaces
kx -n shop delete networkpolicy --all >/dev/null 2>&1
kx -n external-secrets delete networkpolicy --all >/dev/null 2>&1
true
