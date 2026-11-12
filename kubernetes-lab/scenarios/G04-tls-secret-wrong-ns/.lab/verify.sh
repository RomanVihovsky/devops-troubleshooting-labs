ok() { [ "$(https_out secure.lab)" = 200 ]; }
issuer() { echo | openssl s_client -connect 192.168.56.200:443 -servername secure.lab 2>/dev/null | openssl x509 -noout -subject -issuer 2>/dev/null; }
check_eventually 60 "https://secure.lab/ answers 200, certificate verified by the lab CA" ok
for_us() { issuer | grep -q 'secure.lab' && issuer | grep -q 'kubernetes-lab CA'; }
check "the certificate is for secure.lab, issued by the lab CA" for_us
verdict
