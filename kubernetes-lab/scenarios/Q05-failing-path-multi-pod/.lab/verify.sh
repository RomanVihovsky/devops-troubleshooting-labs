err_ok() { case $(answer error) in *pricing*|*timeout*) return 0 ;; *) return 1 ;; esac; }
check "the failing path" answered path /items items "/items/" "get /items"
check "the error message (pricing service timeout)" err_ok
verdict
