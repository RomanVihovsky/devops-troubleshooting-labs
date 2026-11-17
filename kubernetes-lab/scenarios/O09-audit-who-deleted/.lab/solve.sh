when=$(date -u -d "@$(recall o09_when)" +%H:%M)
cat > answers.yaml <<EOF
user: carol
deleted_at: "$when"
client: cleanup-cron
EOF
kx apply -f feature-flags.yaml >/dev/null
