d=stacks/shop
constraint_ok() {
  local c
  c=$(sed -n 's/^\s*required_version\s*=\s*"\(.*\)"/\1/p' "$CI/modules/legacy-tags/main.tf")
  [ -n "$c" ] || return 1
  # probe the constraint with Terraform itself: 1.9.0 and 1.17.1 allowed, 2.0.0 not
  python3 - "$c" <<'PY'
import re, sys
def ok(v, c):
    v = tuple(int(x) for x in v.split("."))
    for part in c.split(","):
        part = part.strip()
        m = re.match(r"(~>|>=|<=|>|<|=|!=)?\s*([0-9.]+)", part)
        op, ver = m.group(1) or "=", m.group(2)
        nums = [int(x) for x in ver.split(".")]
        w = tuple(nums + [0] * (3 - len(nums)))
        if op == "~>":
            hi = list(nums[:-1]); hi[-1] += 1
            hi = tuple(hi + [0] * (3 - len(hi)))
            if not (v >= w and v < hi): return False
        elif op == ">=" and not v >= w: return False
        elif op == ">" and not v > w: return False
        elif op == "<=" and not v <= w: return False
        elif op == "<" and not v < w: return False
        elif op == "=" and v != w: return False
        elif op == "!=" and v == w: return False
    return True
c = sys.argv[1]
sys.exit(0 if ok("1.9.0", c) and ok("1.17.1", c) and not ok("2.0.0", c) else 1)
PY
}
check "CI init + plan of stacks/shop: no changes" plan_clean $d
check "module keeps a constraint: allows 1.9-1.17, refuses 2.x" constraint_ok
verdict
