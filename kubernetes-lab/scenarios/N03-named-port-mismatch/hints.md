## Hint 1
`kubectl -n maps get endpointslices -o yaml` - are there endpoints? With which port?

## Hint 2
A named `targetPort` is looked up in each pod's container ports by **name**.

## Hint 3
`targetPort: web` in the Service, apply.
