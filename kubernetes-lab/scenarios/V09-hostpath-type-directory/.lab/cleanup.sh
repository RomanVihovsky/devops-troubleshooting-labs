for n in $(workers); do nx "$n" 'rm -rf /var/lib/spool-agent' </dev/null; done
true
