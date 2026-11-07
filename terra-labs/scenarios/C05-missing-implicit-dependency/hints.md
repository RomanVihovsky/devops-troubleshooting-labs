## Hint 1
`terraform graph | grep -E 'docker_(container|network)'`. Does any edge connect a container to the network?

## Hint 2
Terraform orders resources by **references**. A string that happens to equal the network's name is not
a reference - so network and containers are created in parallel.

## Hint 3
Use `networks_advanced { name = docker_network.jobs.name }`. It renders to the same string, so nothing
changes for existing containers - but now the dependency is explicit in the graph. (`depends_on` would
work too, but a reference says *why*.)
