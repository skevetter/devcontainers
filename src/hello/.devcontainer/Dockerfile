ARG VARIANT="jammy"
FROM mcr.microsoft.com/devcontainers/base:${VARIANT}

ARG GREETING="hey"
RUN mkdir -p /usr/local/etc \
    && echo "${GREETING}" > /usr/local/etc/greeting.txt
