# syntax=docker/dockerfile:1
# This Dockerfile is adapted from https://github.com/LearningOS/rCore-Tutorial-v3/blob/main/Dockerfile
# with the following major updates:
# - ubuntu 18.04 -> 20.04
# - qemu 5.0.0 -> 7.0.0
# - Extensive comments linking to relevant documentation
FROM ubuntu:20.04

ARG QEMU_VERSION=7.0.0
ARG HOME=/root

# 0. Install general tools
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install -y \
        curl \
        git \
        python3 \
        wget

# 1. Set up QEMU RISC-V
# - https://learningos.github.io/rust-based-os-comp2022/0setup-devel-env.html#qemu
# - https://www.qemu.org/download/
# - https://wiki.qemu.org/Documentation/Platforms/RISCV
# - https://risc-v-getting-started-guide.readthedocs.io/en/latest/linux-qemu.html

# 1.1. Download source
WORKDIR ${HOME}
RUN wget https://download.qemu.org/qemu-${QEMU_VERSION}.tar.xz && \
    tar xvJf qemu-${QEMU_VERSION}.tar.xz

# 1.2. Install dependencies
# - https://risc-v-getting-started-guide.readthedocs.io/en/latest/linux-qemu.html#prerequisites
RUN apt-get install -y \
        autoconf automake autotools-dev curl libmpc-dev libmpfr-dev libgmp-dev \
        gawk build-essential bison flex texinfo gperf libtool patchutils bc \
        zlib1g-dev libexpat-dev git \
        ninja-build pkg-config libglib2.0-dev libpixman-1-dev libsdl2-dev

# 1.3. Build and install from source
WORKDIR ${HOME}/qemu-${QEMU_VERSION}
RUN ./configure --target-list=riscv64-softmmu,riscv64-linux-user && \
    make -j$(nproc) && \
    make install

# 1.4. Clean up
WORKDIR ${HOME}
RUN rm -rf qemu-${QEMU_VERSION} qemu-${QEMU_VERSION}.tar.xz

# 1.5. Sanity checking
RUN qemu-system-riscv64 --version && \
    qemu-riscv64 --version

# 2. Set up Rust
# - https://learningos.github.io/rust-based-os-comp2022/0setup-devel-env.html#qemu
# - https://www.rust-lang.org/tools/install
# - https://github.com/rust-lang/docker-rust/blob/master/Dockerfile-debian.template

# 2.1. Install
ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:$PATH \
    RUST_VERSION=nightly
RUN set -eux; \
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs -o rustup-init; \
    chmod +x rustup-init; \
    ./rustup-init -y --no-modify-path --profile minimal --default-toolchain $RUST_VERSION; \
    rm rustup-init; \
    chmod -R a+w $RUSTUP_HOME $CARGO_HOME;

# 2.2. Sanity checking
RUN rustup --version && \
    cargo --version && \
    rustc --version

# 3. Build env for labs
# See os1/Makefile `env:` for example.
# This avoids having to wait for these steps each time using a new container.
RUN rustup target add riscv64gc-unknown-none-elf && \
    cargo install cargo-binutils --vers ~0.2 && \
    rustup component add rust-src && \
    rustup component add llvm-tools-preview

# Ready to go
WORKDIR ${HOME}
