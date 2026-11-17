# New team members can't get their kubeconfigs
**INC-2836** · P2 · Reporter: platform team

Our onboarding script creates a CertificateSigningRequest for each new engineer and approves it - since yesterday's
controller-manager "cleanup" (*removed flags that only repeat defaults*) the CSRs stay **Approved** but never get a
certificate (`lab-onboard-ana` is one of them). Kubelet serving certificates won't rotate either. The cluster CA is
the right signer.

**Test**: a newly created and approved client CSR gets a certificate signed by the cluster CA within a minute; the
pending `lab-onboard-ana` has its certificate; the control plane is healthy.
