# Solution - bootstrap Python with raw

**Root cause**: Ansible ships modules as Python to the node and runs them there; the minimal image has no
Python, so even fact gathering fails (`/usr/bin/python3: not found`, interpreter discovery finds nothing).

**Fix**: a first play without fact gathering that uses `ansible.builtin.raw` (plain SSH command) to install
Python only when it is missing - then everything else works as before.

**Interview notes**
* Modules that need no Python on the target: `raw`, `script`, and the `ansible.windows` family (PowerShell).
* RedHat family: `dnf install -y python3`; for really tiny targets consider `connection: local` + APIs, or
  network-device collections (no Python on devices).
* `interpreter_python = auto_silent` hides *which* interpreter was found - set it explicitly when images differ.
* Baking Python into the golden image is the better long-term fix; the bootstrap keeps the playbook robust.
