## Hint 1
Version 3 layout: `images.base_image.name`, `dependencies.python` (a list or a requirements file),
`dependencies.ansible_core` / `ansible_runner` (`package_pip: ...` - already in the base, pip just confirms),
`options`, `additional_build_files`, `additional_build_steps`.

## Hint 2
The base image's Python is `/usr/local/bin/python3` -> `dependencies.python_interpreter.python_path`. Without it
the builder looks for `/usr/bin/python3` and stops.

## Hint 3
```yaml
images:
  base_image:
    name: ansiblelab/ee-base:1
dependencies:
  python_interpreter:
    python_path: /usr/local/bin/python3
  ansible_core: {package_pip: ansible-core==2.22.0}
  ansible_runner: {package_pip: ansible-runner}
  python:
    - jmespath
```
