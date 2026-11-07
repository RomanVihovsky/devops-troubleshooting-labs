check "client -> 10.77.0.10:8090 answers" cx 'curl -fs --max-time 4 http://10.77.0.10:8090/'
check "client -> 10.77.0.10:9100 is still blocked" cx '! nc -z -w 3 10.77.0.10 9100'
check "node-exporter still runs on srv" active node-exporter
verdict
