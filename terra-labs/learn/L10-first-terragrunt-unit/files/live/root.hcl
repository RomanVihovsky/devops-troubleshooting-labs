# Shared configuration, included by every unit under live/.

# TODO: locals - read env from the nearest env.hcl

# TODO: remote_state "s3" - bucket acme-tg-state, key per unit, use_lockfile, generated backend.tf
#       Lab only: also set skip_bucket_enforced_tls = true (the fake AWS cannot evaluate
#       aws:SecureTransport, so the TLS-only bucket policy from `backend bootstrap` would lock you out).

# TODO: generate "provider" - aws, region eu-central-1, default_tags { env = ... }

# TODO: inputs = { env = ... }
