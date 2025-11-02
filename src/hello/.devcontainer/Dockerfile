FROM mcr.microsoft.com/devcontainers/base:jammy

ARG GREETING="hey"
RUN mkdir -p /usr/local/etc \
    && echo "${GREETING}" > /usr/local/etc/greeting.txt
