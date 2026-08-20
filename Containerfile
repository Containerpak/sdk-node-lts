FROM ubuntu:26.04 AS fetch

ARG TARGETARCH
ARG NODE_VERSION=24.19.0
ARG NODE_SHA256_AMD64=14b342e71204f811bde6153be8e04b62aef63c236fef92b55f9c83154b409647
ARG NODE_SHA256_ARM64=01443c1e1a29e531ccad5a46fefa6df490d2189c49f7955904aecdbb0fe86fdc

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
