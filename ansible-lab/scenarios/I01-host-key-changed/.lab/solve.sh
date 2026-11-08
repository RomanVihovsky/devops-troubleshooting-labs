ctl 'for h in web2 web2.acme.internal 10.78.0.12; do ssh-keygen -q -R "$h" >/dev/null 2>&1; done
     ssh-keyscan -q -t ed25519 web2 >> ~/.ssh/known_hosts'
ap site.yml
