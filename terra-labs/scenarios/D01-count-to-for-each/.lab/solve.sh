i=0
for s in eu-1 eu-2 us-1 us-2 ap-1 ap-2; do
  printf '\nmoved {\n  from = docker_container.web[%d]\n  to   = docker_container.web["%s"]\n}\n' "$i" "$s" >> web/moved.tf
  i=$((i + 1))
done
apply web
