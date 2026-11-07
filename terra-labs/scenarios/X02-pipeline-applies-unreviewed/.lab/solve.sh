python3 - <<'PY'
p = "ci/pipeline.sh"
s = open(p).read()
s = s.replace('''    terraform plan -input=false -no-color > "$ART/plan.txt"
    echo "plan ready for review: $ART/plan.txt"''', '''    terraform plan -input=false -no-color -out="$ART/tfplan"
    terraform show -no-color "$ART/tfplan" > "$ART/plan.txt"
    echo "plan ready for review: $ART/plan.txt"''')
s = s.replace('''    terraform apply -input=false -no-color -auto-approve''', '''    [ -f "$ART/tfplan" ] || { echo "no reviewed plan ($ART/tfplan) - run plan first" >&2; exit 1; }
    terraform apply -input=false -no-color "$ART/tfplan"   # exactly what was reviewed; refuses stale plans''')
open(p, "w").write(s)
PY
