cxi <<'C'
id ci >/dev/null 2>&1 || useradd -m -s /bin/bash ci
su - ci -c "ssh-keygen -q -t ed25519 -N '' -f ~/.ssh/id_ed25519"
printf 'Host *\n  StrictHostKeyChecking accept-new\n' > /home/ci/.ssh/config; chown ci:ci /home/ci/.ssh/config
C
pub=$(cx 'cat /home/ci/.ssh/id_ed25519.pub')
sxi <<S
install -d -m 700 -o deploy -g deploy /home/deploy/.ssh
echo "$pub" > /home/deploy/.ssh/authorized_keys
chown deploy:deploy /home/deploy/.ssh/authorized_keys; chmod 600 /home/deploy/.ssh/authorized_keys
groupadd -f release && usermod -aG release admin && usermod -aG release deploy
chgrp release /home/deploy && chmod 775 /home/deploy   # "so the release team can drop files"
S
