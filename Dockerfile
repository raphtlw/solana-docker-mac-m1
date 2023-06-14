# Dockerfile
# solana-docker-mac-m1
#
# Created by Raphael Tang on 12/6/2023.
# Licensed 2023 under MIT. All rights reserved.

#  ________  ________  ___       ________  ________   ________
# |\   ____\|\   __  \|\  \     |\   __  \|\   ___  \|\   __  \
# \ \  \___|\ \  \|\  \ \  \    \ \  \|\  \ \  \\ \  \ \  \|\  \
#  \ \_____  \ \  \\\  \ \  \    \ \   __  \ \  \\ \  \ \   __  \
#   \|____|\  \ \  \\\  \ \  \____\ \  \ \  \ \  \\ \  \ \  \ \  \
#     ____\_\  \ \_______\ \_______\ \__\ \__\ \__\\ \__\ \__\ \__\
#    |\_________\|_______|\|_______|\|__|\|__|\|__| \|__|\|__|\|__|
#    \|_________|
#
# This Dockerfile contains a definition for a container which builds Solana from source
# in the build process. It should work on other operating systems too, but don't quote me on that.

# Set directory used for all build generated files
ARG CUBICLE=/root
# Set your solana version here
ARG SOLANA_VERSION=1.14.17
# Set folder name for intermediary files during build step
ARG BUILD_OUTPUT_DIR=${CUBICLE}/solana-output

FROM --platform=linux/arm64 debian:stable-slim as base

SHELL [ "/bin/bash", "-c" ]

RUN apt update && \
    apt-get install -y \
    curl wget neovim fish \
    pkg-config bzip2 \
    && \
    rm -rf /var/lib/apt/lists/*

# Container for building the solana binaries
FROM base as builder
ARG CUBICLE
ARG SOLANA_VERSION
ARG BUILD_OUTPUT_DIR

RUN apt update && \
    apt-get install -y \
    build-essential \
    libssl-dev libudev-dev clang \
    gcc zlib1g-dev llvm cmake make \
    libprotobuf-dev protobuf-compiler \
    perl libfindbin-libs-perl \
    && \
    rm -rf /var/lib/apt/lists/*

# Fetch solana source code
WORKDIR ${CUBICLE}
RUN if [[ "${SOLANA_VERSION}" == "latest" ]] ;\
    then \
      wget -O solana.tar.gz \
        https://github.com/solana-labs/solana/archive/refs/heads/master.tar.gz ;\
    else \
      wget -O solana.tar.gz \
        https://github.com/solana-labs/solana/archive/refs/tags/v${SOLANA_VERSION}.tar.gz ;\
    fi
RUN mkdir solana && \
    tar --extract --verbose --gzip --file solana.tar.gz --strip-components=1 --directory solana

# Setup rust with compatible version
RUN source solana/ci/rust-version.sh && \
    curl https://sh.rustup.rs -sSf | sh -s -- -y --default-toolchain "$rust_stable"
ENV PATH=${CUBICLE}/.cargo/bin:$PATH

# Build Solana binaries
WORKDIR ${CUBICLE}/solana
# FIXME: --validator-only is a temporary fix for
#        [solana-labs/solana issue 31528](https://github.com/solana-labs/solana/issues/31528)
RUN ./scripts/cargo-install-all.sh "${BUILD_OUTPUT_DIR}" --validator-only
RUN cargo build --bin solana-test-validator --release
RUN cd "${BUILD_OUTPUT_DIR}/bin" && "${CUBICLE}/solana/fetch-spl.sh"
RUN cp -f scripts/run.sh "${BUILD_OUTPUT_DIR}/bin/run-cluster"
RUN cp -f fetch-spl.sh "${BUILD_OUTPUT_DIR}/bin/"
RUN cp -f target/release/solana-test-validator "${BUILD_OUTPUT_DIR}/bin/"

# Final resulting multipurpose container
FROM base as final
ARG CUBICLE
ARG SOLANA_VERSION
ARG BUILD_OUTPUT_DIR

COPY --from=builder ${BUILD_OUTPUT_DIR} /usr/

# RPC JSON
EXPOSE 8899/tcp
# RPC pubsub
EXPOSE 8900/tcp
# entrypoint
EXPOSE 8001/tcp
# (future) bank service
EXPOSE 8901/tcp
# bank service
EXPOSE 8902/tcp
# faucet
EXPOSE 9900/tcp
# tvu
EXPOSE 8000/udp
# gossip
EXPOSE 8001/udp
# tvu_forwards
EXPOSE 8002/udp
# tpu
EXPOSE 8003/udp
# tpu_forwards
EXPOSE 8004/udp
# retransmit
EXPOSE 8005/udp
# repair
EXPOSE 8006/udp
# serve_repair
EXPOSE 8007/udp
# broadcast
EXPOSE 8008/udp
# tpu_vote
EXPOSE 8009/udp

SHELL [ "/usr/bin/fish", "-c" ]
RUN chsh -s /usr/bin/fish
ENV SHELL=/usr/bin/fish
ENV LANG=C.UTF-8 LANGUAGE=C.UTF-8 LC_ALL=C.UTF-8

WORKDIR /data
ENTRYPOINT [ "fish", "-c" ]
CMD [ "run-cluster" ]