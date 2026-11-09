# T07: CertificateSigningRequests are cluster-scoped - not removed with the namespace
kx delete csr t07-jane --ignore-not-found >/dev/null 2>&1
true
