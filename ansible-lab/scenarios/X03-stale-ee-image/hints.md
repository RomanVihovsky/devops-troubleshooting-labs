## Hint 1
`cat ci/ee-image`, `docker image inspect acme/ee:1 --format '{{.Created}}'` (from the host), and
`git log --format='%h %ad %s' -- ee/`. When was the image built, and when did the definition change?

## Hint 2
Changing `execution-environment.yml` doesn't change any image - someone has to build and **tag** a new one, and
the CI must be pointed at it. Rebuilding `acme/ee:1` in place would leave every runner that cached `:1` on the old
image (and make "which EE ran this job?" unanswerable).

## Hint 3
In `ee/`: `cp -r /opt/wheels wheels && ansible-builder create` (in `./lab sh`), then on the host
`./lab ee build ee acme/ee:2`, `echo acme/ee:2 > ci/ee-image`, and `./lab ee run acme/ee:2 site.yml`.
