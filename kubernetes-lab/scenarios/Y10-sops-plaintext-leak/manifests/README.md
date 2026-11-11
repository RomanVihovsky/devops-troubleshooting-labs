# newsvc

Redis for the new service. Its password comes from Secret `newsvc/redis-auth`, which is applied from Git:

    cd workspace/gitops
    sops -d secrets/new-service.enc.yaml | kubectl apply -f -
    kubectl -n newsvc rollout restart deploy/redis     # redis reads the password at start

(Argo CD has no SOPS plugin in this lab, so this file is applied by hand.)
