# Base image for the labs' Execution Environments: what an EE needs at minimum (ansible-core,
# ansible-runner, ssh client). Lab EEs (execution-environment.yml) build FROM this - offline.
ARG BASE=python:3.13-slim
FROM ${BASE}
ARG ANSIBLE_CORE_VERSION COLLECTIONS
RUN set -eux; for i in 1 2 3 4 5; do apt-get update && break || sleep 5; done; \
    apt-get install -y --no-install-recommends openssh-client git && rm -rf /var/lib/apt/lists/*
RUN for i in 1 2 3; do pip install --no-cache-dir "ansible-core==${ANSIBLE_CORE_VERSION}" ansible-runner && break || sleep 10; done
RUN set -eux; specs=""; for c in ${COLLECTIONS}; do case $c in ansible.posix*|community.general*) specs="$specs ${c%%:*}:==${c#*:}";; esac; done; \
    ansible-galaxy collection install --no-deps -p /usr/share/ansible/collections $specs
RUN useradd -m -u 1000 runner && mkdir -p /runner && chown runner /runner
WORKDIR /runner
