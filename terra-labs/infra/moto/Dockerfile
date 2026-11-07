# terralab/moto - a throwaway, in-memory "AWS account" for the labs.
# Built from the local python base image (Docker Hub is not needed at build time).
ARG PY_BASE_IMAGE=python:3.12-slim
FROM ${PY_BASE_IMAGE}
ARG MOTO_VERSION
RUN for i in 1 2 3 4 5; do \
      pip install --no-cache-dir "moto[server]==${MOTO_VERSION}" && break || sleep 5; \
    done \
 && python -c "import moto; print('moto', moto.__version__)"
COPY terralab_moto.py /opt/terralab_moto.py
RUN useradd -r -u 10001 moto
USER moto
EXPOSE 5000
HEALTHCHECK --interval=5s --timeout=3s --retries=10 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:5000/moto-api/')"
ENTRYPOINT ["python", "/opt/terralab_moto.py", "-H", "0.0.0.0", "-p", "5000"]
