# New node web2: "Failed to download metadata for repo 'baseos'"
**OPS-324** · P2 · Reporter: platform team

web2 was re-imaged from the vendor's Rocky 9 cloud image. Every package task fails with
`Cannot download repomd.xml`. Our network is air-gapped: the only package source is the internal mirror
`http://repo.acme.internal/rocky9` (trusted, unsigned). All future nodes come from the same vendor image.

**Test**: web2 serves the home page and site.yml converges; on web2 every enabled repo is the internal mirror;
a freshly re-imaged node (vendor repos again) converges in a single run of site.yml.
