# ansible-lab controller, wave 2 layer: ansiblelab/ctl:1 (unchanged - wave 1 is selftested on it) plus
#   * Event-Driven Ansible: a Java runtime (drools) + ansible-rulebook + ansible.eda
#   * cloud inventory: boto3/botocore + amazon.aws
#   * offline ansible-test: pip reads the company wheelhouse (/opt/pypi/sanity, mounted) instead of PyPI
# Python packages come from the cached wheelhouse (cache/pypi/{eda,aws}, staged into the build context by
# ./lab build); the builder stage installs them into /install so the wheels never become an image layer.
ARG BASE=ansiblelab/ctl:1
FROM ${BASE} AS builder
ARG ANSIBLE_RULEBOOK_VERSION BOTO3_VERSION
USER root
COPY pypi /pypi
RUN pip install --no-cache-dir --no-index --find-links /pypi/eda --find-links /pypi/aws --prefix /install \
      "ansible-rulebook==${ANSIBLE_RULEBOOK_VERSION}" "boto3==${BOTO3_VERSION}"
COPY collections /collections
RUN ansible-galaxy collection install --offline --no-deps -p /install/collections /collections/*.tar.gz

FROM ${BASE}
ARG JAVA_PACKAGE SANITY_PIP_VERSION
USER root
RUN set -eux; for i in 1 2 3 4 5; do apt-get update && break || sleep 5; done; \
    for i in 1 2 3 4 5; do apt-get install -y --no-install-recommends ${JAVA_PACKAGE} && break || sleep 5; done; \
    rm -rf /var/lib/apt/lists/*; java -version
COPY --from=builder /install/lib /usr/local/lib
COPY --from=builder /install/bin /usr/local/bin
COPY --from=builder /install/collections/ansible_collections /usr/share/ansible/collections/ansible_collections
ENV JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
# The air gap for pip: no index, only the wheelhouse. ansible-test creates one venv per sanity test and installs
# its frozen requirements with pip; it does not pass PIP_* variables through, but pip always reads /etc/pip.conf.
COPY pip.conf /etc/pip.conf
# pylint's requirement pins dill to a GitHub archive (a direct URL pip can't take from a wheelhouse); the
# wheelhouse carries a wheel built from that exact archive -> pin the version instead of the URL.
RUN set -eux; req=$(python3 -c 'import ansible_test,os;print(os.path.dirname(ansible_test.__file__))')/_data/requirements/sanity.pylint.txt; \
    sed -i "s|^dill @ .*|dill==0.4.2.dev0|" "$req"; grep '^dill' "$req"
# ansible-test bootstraps pip in each venv with a script it downloads from ci-files.testing.ansible.com
COPY get_pip.py /tmp/get_pip.py
RUN install -d -o ops -g ops /home/ops/.ansible /home/ops/.ansible/test /home/ops/.ansible/test/cache \
 && install -o ops -g ops -m 0644 /tmp/get_pip.py "/home/ops/.ansible/test/cache/get_pip_$(echo "$SANITY_PIP_VERSION" | tr . _).py" \
 && rm /tmp/get_pip.py
RUN ansible-rulebook --version | head -1 && python3 -c 'import boto3; print("boto3", boto3.__version__)' \
 && ansible-galaxy collection list -p /usr/share/ansible/collections 2>/dev/null | grep -E 'amazon.aws|ansible.eda'
USER ops
