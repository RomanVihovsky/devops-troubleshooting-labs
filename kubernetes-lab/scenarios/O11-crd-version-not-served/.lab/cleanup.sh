# the student applies the CRD from a file without the lab label: delete it by name (its widgets go with it)
kx delete crd widgets.example.lab --ignore-not-found >/dev/null 2>&1
true
