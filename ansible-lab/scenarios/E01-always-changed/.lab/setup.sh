nx app1 "mkdir -p /opt/acme /tmp/rel && echo 1.0 > /tmp/rel/VERSION && echo 'print(\"acme\")' > /tmp/rel/app.py && tar -czf /opt/acme/release-1.0.tar.gz -C /tmp/rel . && rm -rf /tmp/rel"
ap site.yml
ws_commit "app node"
