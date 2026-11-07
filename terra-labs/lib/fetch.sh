# shellcheck shell=bash
# Downloads for ./lab build. Everything lands in cache/ and is checksum-verified.

# fetch <url> <dest>: resumable download with retries
fetch() {
  local url=$1 dest=$2 i
  for i in 1 2 3 4 5 6; do
    curl -fsSL --retry 3 --retry-delay 3 --connect-timeout 20 -C - -o "$dest.part" "$url" && { mv "$dest.part" "$dest"; return 0; }
    echo "retry $i for $url" >&2; sleep 5
  done
  return 1
}

# fetch_verified <url> <sums_url> <dest> [name_in_sums]
# Downloads <url> unless <dest> already matches the published sha256, then verifies it.
fetch_verified() {
  local url=$1 sums_url=$2 dest=$3 name=${4:-$(basename "$1")} sums want got
  sums="$dest.sha256sums"
  [ -s "$sums" ] || fetch "$sums_url" "$sums" || return 1
  want=$(awk -v n="$name" '$2==n || $2=="*"n {print $1}' "$sums" | head -1)
  [ -n "$want" ] || { echo "no checksum for $name in $sums_url" >&2; return 1; }
  if [ -f "$dest" ]; then
    got=$(sha256sum "$dest" | cut -d' ' -f1)
    [ "$got" = "$want" ] && return 0
    rm -f "$dest"
  fi
  fetch "$url" "$dest" || return 1
  got=$(sha256sum "$dest" | cut -d' ' -f1)
  if [ "$got" != "$want" ]; then
    echo "sha256 mismatch for $dest: got $got, want $want" >&2
    rm -f "$dest"
    return 1
  fi
}
