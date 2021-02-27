FROM ubuntu:18.04
LABEL maintainer="dinghao188" \
      version="1.1" \
      description="ubuntu 18.04 with tools for tsinghua's rCore-Tutorial-V3"

#install some deps
RUN set -x \
    && apt-get update \
    && apt-get install -y curl wget autoconf automake autotools-dev curl libmpc-dev libmpfr-dev libgmp-dev \
              gawk build-essential bison flex texinfo gperf libtool patchutils bc xz-utils \
              zlib1g-dev libexpat-dev pkg-config  libglib2.0-dev libpixman-1-dev git tmux python3 

#install rust and qemu
RUN set -x; \
    RUSTUP='/root/rustup.sh' \
    && cd $HOME \
    #install rust
    && curl https://sh.rustup.rs -sSf > $RUSTUP && chmod +x $RUSTUP \
    && $RUSTUP -y --default-toolchain nightly --profile minimal \

    #compile qemu
    && wget https://ftp.osuosl.org/pub/blfs/conglomeration/qemu/qemu-5.0.0.tar.xz \
    && tar xvJf qemu-5.0.0.tar.xz \
    && cd qemu-5.0.0 \
    && ./configure --target-list=riscv64-softmmu,riscv64-linux-user \
    && make -j$(nproc) install \
    && cd $HOME && rm -rf qemu-5.0.0 qemu-5.0.0.tar.xz

#for chinese network
RUN set -x; \
    APT_CONF='/etc/apt/sources.list'; \
    CARGO_CONF='/root/.cargo/config'; \
    BASHRC='/root/.bashrc' \
    && echo 'export RUSTUP_DIST_SERVER=https://mirrors.ustc.edu.cn/rust-static' >> $BASHRC \
    && echo 'export RUSTUP_UPDATE_ROOT=https://mirrors.ustc.edu.cn/rust-static/rustup' >> $BASHRC \
    && touch $CARGO_CONF \
    && echo '[source.crates-io]' > $CARGO_CONF \
    && echo "replace-with = 'ustc'" >> $CARGO_CONF \
    && echo '[source.ustc]' >> $CARGO_CONF \
    && echo 'registry = "git://mirrors.ustc.edu.cn/crates.io-index"' >> $CARGO_CONF