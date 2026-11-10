## Hint 1
`kubectl -n invoices logs <pod> --previous` - where does it try to write?

## Hint 2
A read-only rootfs is fine as long as every path the app writes to is a volume.

## Hint 3
An `emptyDir` mounted at `/tmp`, apply.
