sxi <<'S'
L=/var/log/nginx/access.log.1
{
  echo "1: $(awk '$9 == 404 {print $1}' $L | sort | uniq -c | sort -rn | head -1 | awk '{print $2}')"
  echo "2: $(awk '$7 == "/wp-login.php" {print $1}' $L | sort -u | wc -l)"
  echo "3: $(awk '{print substr($4, 14, 5)}' $L | sort | uniq -c | sort -rn | head -1 | awk '{print $2}')"
} > /home/admin/answers.txt
S
