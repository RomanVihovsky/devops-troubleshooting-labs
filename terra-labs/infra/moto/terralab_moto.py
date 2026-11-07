"""moto_server with the lab's fidelity patches (documented in docs/FAULTS.md).

1. S3 CreateBucket: since 2025 AWS accepts <Tags> inside CreateBucketConfiguration and the
   Terraform AWS provider 6.x sends bucket tags that way. moto 5.2 ignores them, which made every
   tagged bucket show a perpetual tag diff. We store them like PutBucketTagging would.
"""
import sys

import xmltodict
from moto.s3 import responses as s3_responses

_orig_bucket_put = s3_responses.S3Response._bucket_response_put


def _bucket_response_put(self, request, bucket_name, querystring):
    result = _orig_bucket_put(self, request, bucket_name, querystring)
    if not querystring and self.body:
        try:
            cfg = xmltodict.parse(self.body).get("CreateBucketConfiguration") or {}
            tags = (cfg.get("Tags") or {}).get("Tag")
        except Exception:  # not XML / no config: plain CreateBucket
            tags = None
        if tags:
            if isinstance(tags, dict):
                tags = [tags]
            self.backend.put_bucket_tagging(
                bucket_name, {t["Key"]: t.get("Value") or "" for t in tags}
            )
    return result


s3_responses.S3Response._bucket_response_put = _bucket_response_put

if __name__ == "__main__":
    from moto.server import main

    sys.exit(main())
