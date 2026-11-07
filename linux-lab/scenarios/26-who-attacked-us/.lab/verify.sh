ans() { sx "grep -E '^$1:' /home/admin/answers.txt 2>/dev/null | head -1 | tr -d ' \r'"; }
want() { recall answers | grep -E "^$1:" | tr -d ' '; }
check "answer 1 (top 404 IP) is correct" test "$(ans 1)" = "$(want 1)"
check "answer 2 (distinct /wp-login.php IPs) is correct" test "$(ans 2)" = "$(want 2)"
check "answer 3 (busiest minute) is correct" test "$(ans 3)" = "$(want 3)"
verdict
