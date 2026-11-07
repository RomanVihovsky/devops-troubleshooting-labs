# fetch <url> <dest>: resumable download with retries
fetch() {
  local url=$1 dest=$2 i
  for i in 1 2 3 4 5 6; do
    curl -fL --retry 3 --retry-delay 3 --connect-timeout 20 -C - -o "$dest.part" "$url" && { mv "$dest.part" "$dest"; return 0; }
    echo "retry $i for $url" >&2; sleep 5
  done
  return 1
}
