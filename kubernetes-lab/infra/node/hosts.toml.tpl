# containerd mirror for @UPSTREAM@: pull from the lab registry on k8s-gw first. Images are stored there under
# their upstream host (registry.lab:5000/@UPSTREAM@/<path>), hence override_path. Upstream is only the fallback.
server = "@SERVER@"

[host."http://registry.lab:5000/v2/@UPSTREAM@"]
  capabilities = ["pull", "resolve"]
  override_path = true
