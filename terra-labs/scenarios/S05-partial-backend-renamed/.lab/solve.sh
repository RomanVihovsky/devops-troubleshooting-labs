python3 - <<'PY'
p = "ci/plan.sh"
s = open(p).read()
s = s.replace('''args=()
[ -f "backend/$env.hcl" ] && args+=("-backend-config=backend/$env.hcl")

terraform init -input=false -no-color "${args[@]}"''', '''cfg="backend/$env.s3.tfbackend"
[ -f "$cfg" ] || { echo "no backend config $cfg for env '$env'" >&2; exit 2; }

terraform init -input=false -no-color -backend-config="$cfg"''')
open(p, "w").write(s)
PY
