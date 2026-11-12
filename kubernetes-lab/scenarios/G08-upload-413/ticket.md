# Uploads above 1 MB fail with 413
**INC-2565** · P2 · Reporter: team media

Uploads to `media.lab/upload` larger than about 1 MB fail with *413 Request Entity Too Large*. The app accepts up to
64 MiB (`MAX_UPLOAD_MB`), and our customers send up to ~10 MiB. Keep a size limit in front of the app (security
wants one), just a sensible one: at least 16 MiB, at most the app's 64 MiB.

**Test**: a 10 MiB upload through `media.lab` answers 200; the ingress still enforces a body limit between 16 MiB and
64 MiB.
