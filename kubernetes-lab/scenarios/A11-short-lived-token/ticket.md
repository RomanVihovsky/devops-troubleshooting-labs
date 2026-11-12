# The deploy pipeline gets 401 from the API
**INC-2613** · P2 · Reporter: CI team

Our pipeline authenticates as ServiceAccount `ci2/ci-bot` with the token in `workspace/A11/ci-token.txt`. It worked
until this morning; now every call is *401 Unauthorized*. Someone created that token "from the runner pod" last
week. Security allows a **long-lived token Secret** for this one ServiceAccount (it will be rotated by hand). Put a
working token into `ci-token.txt` - one that survives runner restarts.

**Test**: the token in `workspace/A11/ci-token.txt` authenticates as `system:serviceaccount:ci2:ci-bot` and can list
pods in `ci2`; it comes from a Secret of type `kubernetes.io/service-account-token` for `ci-bot`.
