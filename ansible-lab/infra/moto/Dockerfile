# ansiblelab/moto - a throwaway, in-memory "AWS account" (EC2 API) for the cloud-inventory labs, the same idea
# as ../terra-labs (moto server). Installed from the cached wheelhouse (cache/wheels/moto) in a builder stage.
ARG BASE=python:3.13-slim
FROM ${BASE} AS builder
ARG MOTO_VERSION
COPY wheels /wheels
RUN pip install --no-cache-dir --no-index --find-links /wheels/moto --prefix /install "moto[ec2,server]==${MOTO_VERSION}"

FROM ${BASE}
COPY --from=builder /install /usr/local
RUN python -c "import moto; print('moto', moto.__version__)" && useradd -r -u 10001 moto
USER moto
EXPOSE 4566
HEALTHCHECK --interval=5s --timeout=3s --retries=10 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:4566/moto-api/')"
ENTRYPOINT ["moto_server", "-H", "0.0.0.0", "-p", "4566"]
