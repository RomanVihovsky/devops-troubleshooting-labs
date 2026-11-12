; Gitea on k8s-gw (/etc/gitea/app.ini) - the lab's Git server for Argo CD. @SECRET@ values are generated once.
APP_NAME = kubernetes-lab Git
RUN_USER = git
RUN_MODE = prod
WORK_PATH = /var/lib/gitea

[server]
DOMAIN           = git.lab
HTTP_ADDR        = 0.0.0.0
HTTP_PORT        = 3000
ROOT_URL         = http://git.lab:3000/
DISABLE_SSH      = true
OFFLINE_MODE     = true
LFS_START_SERVER = false

[database]
DB_TYPE = sqlite3
PATH    = /var/lib/gitea/data/gitea.db

[repository]
ROOT           = /var/lib/gitea/data/repositories
DEFAULT_BRANCH = main

[security]
INSTALL_LOCK   = true
SECRET_KEY     = @SECRET_KEY@
INTERNAL_TOKEN = @INTERNAL_TOKEN@

[oauth2]
JWT_SECRET = @JWT_SECRET@

[service]
DISABLE_REGISTRATION = true
REQUIRE_SIGNIN_VIEW  = true

[mailer]
ENABLED = false

[log]
MODE      = file
LEVEL     = Info
ROOT_PATH = /var/lib/gitea/log
