## Hint 1
`ansible-galaxy collection list community.general` - how many copies are there, and where?
`ansible-config dump --only-changed` shows the configured search path.

## Hint 2
The first location that has the collection wins - the whole collection, not module by module. Is there a
`collections/` directory in the repo? What version is it (`MANIFEST.json`)? `git log -- collections`.

## Hint 3
Remove the vendored copy **completely** (`git rm -r collections/`, then make sure the directory is gone) and the
`./collections` entry from `collections_path`. Ansible also searches a `collections/` directory next to the
playbook on its own - even without the config entry.
