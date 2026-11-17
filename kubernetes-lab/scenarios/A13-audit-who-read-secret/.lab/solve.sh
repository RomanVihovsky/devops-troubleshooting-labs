source "$SCN/.lab/facts.sh"
cat > answers.yaml <<EOF
service_account: system:serviceaccount:ci:reporter
pod: $(a13_pod)
user: bob
EOF
