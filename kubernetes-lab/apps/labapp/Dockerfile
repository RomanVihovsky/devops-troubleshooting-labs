# labapp - kubernetes-lab demo service (stdlib-only Python, no pip install).
# Variants are build args, see README.md "Image tags" and build.sh.
FROM python:3.12-slim

ARG APP_VERSION=1.4
# 10001 = non-root (the chart runs with runAsNonRoot). Build with APP_UID=0 for the "-root" tag.
ARG APP_UID=10001
# Comma list of settings this release refuses to start without (used for the broken 1.5 tag).
ARG REQUIRED_ENV=""

LABEL org.opencontainers.image.title="labapp" \
      org.opencontainers.image.description="kubernetes-lab demo service" \
      org.opencontainers.image.version="${APP_VERSION}"

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    APP_VERSION=${APP_VERSION} \
    REQUIRED_ENV=${REQUIRED_ENV}

COPY labapp.py /app/labapp.py
RUN chmod 0755 /app/labapp.py \
 && ln -s /app/labapp.py /usr/local/bin/labapp \
 && mkdir -p /var/log/labapp /data \
 && chown ${APP_UID}:0 /var/log/labapp /data \
 && chmod 0775 /var/log/labapp /data

USER ${APP_UID}
WORKDIR /app
EXPOSE 8080
ENTRYPOINT ["labapp"]
CMD ["serve"]
