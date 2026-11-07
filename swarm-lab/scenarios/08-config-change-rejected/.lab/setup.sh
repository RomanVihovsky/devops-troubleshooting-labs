deploy_stack
retry 60 svc_converged app_web
echo "Welcome" > "$WORK_DIR/greeting.txt"   # the colleague's edit
