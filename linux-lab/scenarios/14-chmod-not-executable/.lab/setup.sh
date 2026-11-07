sxi <<'S'
printf '#!/bin/bash\necho "deployed version 1.4.2"\n' > /usr/local/bin/deploy.sh
chmod 644 /usr/local/bin/deploy.sh
/usr/bin/chmod -x /usr/bin/chmod
S
remember sum "$(sx 'md5sum /usr/bin/chmod | cut -d" " -f1')"
