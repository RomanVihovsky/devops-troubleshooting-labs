# P03: labapp:1.6 is an arm64 image (single-arch manifest) - on the amd64 nodes: exec format error
kns analytics
ka -f etl.yaml
crashing() { crashlooping analytics app=etl; }
retry 150 crashing || die "etl did not crash"
