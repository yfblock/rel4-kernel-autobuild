FROM debian:bookworm

RUN apt-get update -q && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    git \
    # for seL4
    gcc-aarch64-linux-gnu \
    python3-dev \
    python3-venv \
    cmake \
    ninja-build \
    device-tree-compiler \
    libxml2-utils \
    qemu-utils \
    qemu-system-arm \
    qemu-efi-aarch64 \
    ipxe-qemu \
    # for bindgen
    libclang-dev \
    # for test script
    python3-pexpect \
    # for hacking
    bash-completion \
    man \
    sudo \
    && rm -rf /var/lib/apt/lists/*

ARG UID
ARG GID

RUN set -eux; \
    if [ $UID -eq 0 ]; then \
        if [ $GID -ne 0 ]; then \
            echo "error: \$UID == 0 but \$GID != 0" >&2; \
            exit 1; \
        fi; \
    else \
        if getent passwd $UID; then \
            echo "error: \$UID $UID already exists" >&2; \
            exit 1; \
        fi; \
        if ! getent group $GID; then \
            groupadd --gid $GID x; \
        fi; \
        useradd --uid $UID --gid $GID --groups sudo --create-home x; \
    fi;

RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

USER $UID

RUN cd ~; \
    python3 -m venv pyenv; \
    export PATH=$(realpath ./pyenv/bin):$PATH; \
    pip install pyyaml; \
    pip install pyfdt; \
    pip install jinja2; \
    pip install six; \
    pip install future; \
    pip install ply;

RUN set -eux; \
    if [ $UID -ne 0 ]; then \
        curl -sSf https://sh.rustup.rs | \
            bash -s -- -y --no-modify-path --default-toolchain nightly; \
    fi;

ENV PATH=/home/x/pyenv/bin:/home/x/.cargo/bin:$PATH

ENV SHELL=/bin/bash

RUN rustup component add rust-src --toolchain nightly-x86_64-unknown-linux-gnu

WORKDIR /work
