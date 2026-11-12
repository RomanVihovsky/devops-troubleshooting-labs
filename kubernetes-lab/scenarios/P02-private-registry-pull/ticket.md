# vendor-api: ImagePullBackOff from our private registry
**INC-2451** · P2 · Reporter: team vendor

`vendor-api` (namespace `vendor`, `workspace/P02/vendor-api.yaml`) must run the image from our **private**
registry `registry.lab:5001` (licensing: never the public `:5000` copy). Its pods sit in `ImagePullBackOff`:
*pull access denied ... authorization failed*. The CI team says the pull credentials exist - "it's the
`regcred` Secret, we use it every day".

**Test**: `vendor-api` has 2 Ready pods running `registry.lab:5001/lab/labapp:1.4`; they pull with a pull
Secret that lives in `vendor`; the private registry still refuses anonymous pulls.
