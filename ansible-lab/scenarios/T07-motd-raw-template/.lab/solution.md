# Solution - untrusted data is never templated (2.19+)

**Root cause**: `copy: content: "{{ lookup('file', 'motd.j2') }}"` reads the template file as *data*. Before
2.19 Ansible recursively templated any string containing `{{`, so it "worked". The 2.19 trust model renders
only trusted templates (playbooks, vars files, `template` sources); file contents stay literal.

**Fix**: use the `template` module (or `lookup('ansible.builtin.template', ...)`).

**Interview notes**
* Why the change: re-templating untrusted data (module output, facts, API responses) let remote data
  execute Jinja on the controller - template injection.
* If you really need to render a string at runtime, it must come from a trusted source; there is no
  "trust this" filter for data you got from a host.
* Similar silent change: `lookup('pipe', ...)` / registered stdout containing `{{` are no longer expanded.
