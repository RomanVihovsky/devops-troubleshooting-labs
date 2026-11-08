# Solution - generic modules, OS-specific names in vars

**Root cause**: the role calls `ansible.builtin.apt` and hard-codes `apache2`. Rocky has dnf and calls Apache
`httpd` (package and service).

**Fix**: `package`/`service` modules + `vars/<os_family>.yml` loaded with `first_found` (distribution first, then
family, so a `Rocky.yml` could override `RedHat.yml`).

**Interview notes**
* `package` delegates to the OS's package manager module; options specific to apt/dnf (`update_cache`,
  `cache_valid_time`, `enablerepo`) need the specific module - guard those with `when` or `module_defaults`.
* Other classic differences: config dirs (`/etc/apache2` vs `/etc/httpd`), users (`www-data` vs `apache`),
  firewall (nftables/ufw vs firewalld), SELinux on EL.
* Declare supported platforms in `meta/main.yml` and test both in molecule.
