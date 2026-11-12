source "$SCN/.lab/facts.sh"
cat > answers.yaml <<YML
bad_image: $(q04_bad)
last_good_image: $(q04_good)
missing_setting: SESSION_SECRET
exit_code: $(q04_exit)
YML
