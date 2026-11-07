## Hint 1
`docker service ps --no-trunc app_api` - read the ERROR column of the rejected tasks,
and note which node each task was on.
## Hint 2
Every node runs its **own** dockerd with its **own** image store. Compare
`docker images` on manager1 and on a worker (`./lab sh worker1`).
## Hint 3
Workers try to pull `lab/report-api:1.4` from Docker Hub (that's what an image name
without a registry host means). Put the image in a registry every node can reach
(`registry:5000`) and point the service at it.
