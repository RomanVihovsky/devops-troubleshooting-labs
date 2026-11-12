# A01: the student's objects may sit in default (not labelled)
kx -n default delete role pod-lister --ignore-not-found >/dev/null 2>&1
kx -n default delete rolebinding scraper-pod-lister --ignore-not-found >/dev/null 2>&1
true
