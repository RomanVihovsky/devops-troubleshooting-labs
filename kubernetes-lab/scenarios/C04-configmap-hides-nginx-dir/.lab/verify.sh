header() {
  kx -n web run "lab-probe-$RANDOM" --rm -i --restart=Never --quiet --image="$BUSYBOX_IMAGE" --labels="$LAB_LABEL=$LAB_ID" \
    --command -- sh -c 'wget -S -q -O /dev/null -T 5 http://web.web.svc/ 2>&1' 2>/dev/null | grep -qi 'X-Served-By: web-c04'
}
image_mime() { ! kx -n web get cm -o json | jq -e '[.items[].data // {} | keys[] | select(. == "mime.types")] | length > 0' >/dev/null \
               && [ "$(kx -n web exec deploy/web -- sh -c 'grep -c "text/html" /etc/nginx/mime.types' 2>/dev/null)" -ge 1 ]; }
check_eventually 150 "web: 2 Ready pods" deploy_ready web web 2
check_eventually 60 "http://web.web.svc/ answers 200" http_ok web http://web.web.svc/
check "our config is active (X-Served-By: web-c04)" header
check "the image's own mime.types is in use (none in a ConfigMap)" image_mime
verdict
