sed -i 's/^    version: main$/    version: v1.2.0/' requirements.yml
run_logged "$SETUP_LOG" ctl "sh ci/pipeline.sh"
