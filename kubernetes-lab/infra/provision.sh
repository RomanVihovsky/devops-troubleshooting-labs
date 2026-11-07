# Runs ON the lab VM (via ssh, as user lab with passwordless sudo). Idempotent.
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
for i in 1 2 3 4 5; do sudo apt-get update -qq && break || sleep 10; done
for i in 1 2 3 4 5; do
  sudo apt-get install -y -qq docker.io jq curl ca-certificates bash-completion sysstat >/dev/null && break || sleep 10
done
sudo install -m 755 /tmp/kind /usr/local/bin/kind
sudo install -m 755 /tmp/kubectl /usr/local/bin/kubectl
rm -f /tmp/kind /tmp/kubectl
printf 'fs.inotify.max_user_watches = 524288\nfs.inotify.max_user_instances = 512\n' | sudo tee /etc/sysctl.d/90-kind.conf >/dev/null
sudo sysctl -q --system
sudo usermod -aG docker lab
sudo systemctl enable --now docker >/dev/null 2>&1
grep -q 'alias k=kubectl' ~/.bashrc || cat >> ~/.bashrc <<'B'
source <(kubectl completion bash); alias k=kubectl; complete -o default -F __start_kubectl k
B
echo "provisioned: $(docker --version | cut -d, -f1), $(kind version | cut -d' ' -f1-2), kubectl $(kubectl version --client -o json | jq -r .clientVersion.gitVersion)"
