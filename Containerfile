FROM ubuntu:26.04 AS fetch

ARG TARGETARCH
ARG NODE_VERSION=24.21.0
ARG NODE_SHA256_AMD64=fd8e59d5a511510f6a298afb548f18c7d2b1be404d8b4a27d94fbe49f56cb2d6
ARG NODE_SHA256_ARM64=6ad1325edbdb5649c379b75a237147a666c95d4f9ae8d340fef2d1575d289ad2

COPY cpak-apt.conf /etc/apt/apt.conf.d/90cpak
COPY --chmod=0755 cpak-clean-junk /usr/bin/cpak-clean-junk

RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates curl xz-utils && \
    case "$TARGETARCH" in \
        amd64) nodearch=x64; checksum="$NODE_SHA256_AMD64" ;; \
        arm64) nodearch=arm64; checksum="$NODE_SHA256_ARM64" ;; \
        *) echo "unsupported architecture: $TARGETARCH" >&2; exit 1 ;; \
    esac && \
    archive="node-v${NODE_VERSION}-linux-${nodearch}.tar.xz" && \
    curl -fsSLo "/tmp/${archive}" "https://nodejs.org/dist/v${NODE_VERSION}/${archive}" && \
    echo "${checksum}  /tmp/${archive}" | sha256sum -c - && \
    mkdir -p /opt/node && \
    tar -xJf "/tmp/${archive}" -C /opt/node --strip-components=1 && \
    cpak-clean-junk

FROM ghcr.io/containerpak/base:main

COPY --from=fetch /opt/node/ /usr/local/

ENV PATH=/usr/local/bin:${PATH}
