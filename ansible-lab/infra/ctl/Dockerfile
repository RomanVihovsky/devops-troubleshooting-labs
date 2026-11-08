# ansible-lab controller ("your laptop / the CI runner"): Python 3.13 + ansible-core and the dev tools,
# pinned via build args from versions.env. Collections are installed explicitly (no community bundle).
ARG BASE=python:3.13-slim
FROM ${BASE}
ARG UID=1000
ARG GID=1000
ARG ANSIBLE_CORE_VERSION ANSIBLE_LINT_VERSION MOLECULE_VERSION ANSIBLE_NAVIGATOR_VERSION \
    ANSIBLE_BUILDER_VERSION YAMLLINT_VERSION TESTINFRA_VERSION COLLECTIONS
ENV DEBIAN_FRONTEND=noninteractive PIP_DISABLE_PIP_VERSION_CHECK=1 PYTHONDONTWRITEBYTECODE=1
RUN set -eux; \
    for i in 1 2 3 4 5; do apt-get update && break || sleep 5; done; \
    for i in 1 2 3 4 5; do apt-get install -y --no-install-recommends \
      openssh-client git rsync acl jq curl less vim-tiny nano bash-completion make tree \
      && break || sleep 5; done; \
    rm -rf /var/lib/apt/lists/*
RUN for i in 1 2 3; do pip install --no-cache-dir \
      "ansible-core==${ANSIBLE_CORE_VERSION}" "ansible-lint==${ANSIBLE_LINT_VERSION}" \
      "molecule==${MOLECULE_VERSION}" "ansible-navigator==${ANSIBLE_NAVIGATOR_VERSION}" \
      "ansible-builder==${ANSIBLE_BUILDER_VERSION}" "yamllint==${YAMLLINT_VERSION}" \
      "pytest-testinfra==${TESTINFRA_VERSION}" jmespath netaddr && break || sleep 10; done \
 && ansible --version
RUN set -eux; specs=""; for c in ${COLLECTIONS}; do specs="$specs ${c%%:*}:==${c#*:}"; done; \
    for i in 1 2 3; do ansible-galaxy collection install --no-deps -p /usr/share/ansible/collections $specs && break || sleep 10; done; \
    ansible-galaxy collection list -p /usr/share/ansible/collections
RUN groupadd -g "${GID}" ops && useradd -m -u "${UID}" -g "${GID}" -s /bin/bash ops \
 && mkdir -p /work /ci && chown ops:ops /work /ci
COPY bashrc /etc/profile.d/zz-ansiblelab.sh
USER ops
WORKDIR /work
CMD ["sleep", "infinity"]
