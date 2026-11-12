# backend unreachable since "backend-allow" was applied
**INC-2571** · P2 · Reporter: team shopx

We applied `backend-allow` (`workspace/X02/backend-allow.yaml`) so that only the frontend may call `backend` on
8080. Now the frontend can't connect either. Keep the intent: frontend (pods labelled `app: frontend`) allowed,
everyone else blocked.

**Test**: pods labelled `app: frontend` in `shopx` connect to `backend:8080`; other pods (e.g. `app: reports`) are
still blocked.
