cp "$SCN/.lab/before/main.tf" web/main.tf
apply web
for s in eu-1 eu-2 us-1 us-2 ap-1 ap-2; do remember_ctr "tfl-web-$s"; done
ws_commit "web: six regional frontends"
cp "$SCN/files/web/main.tf" web/main.tf
ws_commit "web: for_each over sites (removing a site no longer renumbers the rest)" "Kim (web)"
