## Hint 1
`kubectl get nodes -o custom-columns=NAME:.metadata.name,CALICO:.metadata.annotations.projectcalico\.org/IPv4Address` -
which address did each node register for the overlay?

## Hint 2
The VXLAN tunnel endpoint of a node is its **autodetected** Calico address. `can-reach=1.1.1.1` takes the address of
the interface the kernel would use to reach 1.1.1.1 - the default route, i.e. the NAT NIC `10.0.2.15`, identical on
every VM. Other nodes send w3's traffic to "10.0.2.15" - i.e.
to themselves.

## Hint 3
Set `IP_AUTODETECTION_METHOD=cidr=192.168.56.0/24` (or `interface=enp0s8`), put `updateStrategy` back to
`RollingUpdate`, and recreate w3's calico-node pod. The node's annotation updates and traffic flows again.
