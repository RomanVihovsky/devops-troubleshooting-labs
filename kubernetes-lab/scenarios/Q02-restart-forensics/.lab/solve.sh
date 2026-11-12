source "$SCN/.lab/facts.sh"
cat > answers.yaml <<YML
container: $(q02_restarted)
reason: $(q02_field reason)
exit_code: $(q02_field exitCode)
memory_limit: $(q02_limit)
YML
