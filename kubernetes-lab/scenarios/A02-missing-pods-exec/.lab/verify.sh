check "anna can exec (create pods/exec) in team-blue" can_i anna create pods --subresource=exec -n team-blue
check "anna can list pods in team-blue" can_i anna list pods -n team-blue
check "anna can read logs in team-blue" can_i anna get pods --subresource=log -n team-blue
check "anna can NOT delete pods in team-blue" not can_i anna delete pods -n team-blue
check "anna can NOT read secrets in team-blue" not can_i anna get secrets -n team-blue
check "anna can NOT exec in default" not can_i anna create pods --subresource=exec -n default
verdict
