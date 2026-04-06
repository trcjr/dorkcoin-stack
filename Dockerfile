FROM debian:trixie-slim@sha256:26f98ccd92fd0a44d6928ce8ff8f4921b4d2f535bfa07555ee5d18f61429cf0c AS builder

ARG DEBIAN_SNAPSHOT=20260406T000000Z
ARG CA_CERTIFICATES_VERSION=20250419
ARG CURL_VERSION=8.14.1-2+deb13u2
ARG GIT_VERSION=1:2.47.3-0+deb13u1
ARG PKG_CONFIG_VERSION=1.8.1-4
ARG LIBTOOL_VERSION=2.5.4-4
ARG AUTOTOOLS_DEV_VERSION=20240727.1
ARG AUTOCONF_VERSION=2.72-3.1
ARG AUTOMAKE_VERSION=1:1.17-4
ARG BINUTILS_VERSION=2.44-3
ARG BUILD_ESSENTIAL_VERSION=12.12
ARG BSDEXTRAUTILS_VERSION=2.41-5
ARG PYTHON3_VERSION=3.13.5-1
ARG LIBEVENT_DEV_VERSION=2.1.12-stable-10+b1
ARG LIBBOOST_FILESYSTEM_DEV_VERSION=1.83.0.2+b2
ARG LIBBOOST_SYSTEM_DEV_VERSION=1.83.0.2+b2
ARG LIBBOOST_PROGRAM_OPTIONS_DEV_VERSION=1.83.0.2+b2
ARG LIBBOOST_THREAD_DEV_VERSION=1.83.0.2+b2
ARG LIBBOOST_CHRONO_DEV_VERSION=1.83.0.2+b2
ARG LIBBOOST_RANDOM_DEV_VERSION=1.83.0.2+b2
ARG LIBSQLITE3_DEV_VERSION=3.46.1-7+deb13u1
ARG LIBZMQ3_DEV_VERSION=4.3.5-1+b3
ARG SYSTEMTAP_SDT_DEV_VERSION=5.1-5
ARG LIBQRENCODE_DEV_VERSION=4.1.1-2
ARG LIBSSL_DEV_VERSION=3.5.5-1~deb13u1
ARG DORKCOIN_REPO_URL=https://github.com/dorkcoinorg/dorkcoin.git
ARG DORKCOIN_REF=v13.2
ARG DORKCOIN_COMMIT=a452ce5c9a4f0ba8eb699ede2b97d2b56f403d2d
ARG BDB_URL=https://download.oracle.com/berkeley-db/db-6.2.32.NC.tar.gz
ARG BDB_SHA256=d86cf1283c519d42dd112b4501ecb2db11ae765b37a1bdad8f8cb06b0ffc69b8
ARG MAKE_JOBS=1

ENV DEBIAN_FRONTEND=noninteractive
ENV BDB_CFLAGS=-I/opt/bdb-6.2/include
ENV BDB_LIBS=/opt/bdb-6.2/lib/libdb_cxx-6.2.a\ /opt/bdb-6.2/lib/libdb-6.2.a

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN rm -f /etc/apt/sources.list.d/debian.sources \
 && printf 'deb [check-valid-until=no] http://snapshot.debian.org/archive/debian/%s trixie main\n' "${DEBIAN_SNAPSHOT}" > /etc/apt/sources.list \
 && printf 'Acquire::Check-Valid-Until "false";\n' > /etc/apt/apt.conf.d/99snapshot \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
     ca-certificates="${CA_CERTIFICATES_VERSION}" \
     curl="${CURL_VERSION}" \
     git="${GIT_VERSION}" \
     pkg-config="${PKG_CONFIG_VERSION}" \
     libtool="${LIBTOOL_VERSION}" \
     autotools-dev="${AUTOTOOLS_DEV_VERSION}" \
     autoconf="${AUTOCONF_VERSION}" \
     automake="${AUTOMAKE_VERSION}" \
     binutils="${BINUTILS_VERSION}" \
     build-essential="${BUILD_ESSENTIAL_VERSION}" \
     bsdextrautils="${BSDEXTRAUTILS_VERSION}" \
     python3="${PYTHON3_VERSION}" \
     libevent-dev="${LIBEVENT_DEV_VERSION}" \
     libboost-filesystem-dev="${LIBBOOST_FILESYSTEM_DEV_VERSION}" \
     libboost-system-dev="${LIBBOOST_SYSTEM_DEV_VERSION}" \
     libboost-program-options-dev="${LIBBOOST_PROGRAM_OPTIONS_DEV_VERSION}" \
     libboost-thread-dev="${LIBBOOST_THREAD_DEV_VERSION}" \
     libboost-chrono-dev="${LIBBOOST_CHRONO_DEV_VERSION}" \
     libboost-random-dev="${LIBBOOST_RANDOM_DEV_VERSION}" \
     libsqlite3-dev="${LIBSQLITE3_DEV_VERSION}" \
     libzmq3-dev="${LIBZMQ3_DEV_VERSION}" \
     systemtap-sdt-dev="${SYSTEMTAP_SDT_DEV_VERSION}" \
     libqrencode-dev="${LIBQRENCODE_DEV_VERSION}" \
     libssl-dev="${LIBSSL_DEV_VERSION}" \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /tmp
RUN curl -fsSL "${BDB_URL}" -o db-6.2.32.NC.tar.gz \
 && echo "${BDB_SHA256}  db-6.2.32.NC.tar.gz" | sha256sum -c - \
 && tar -xzf db-6.2.32.NC.tar.gz \
 && cd db-6.2.32.NC/build_unix \
 && ../dist/configure --prefix=/opt/bdb-6.2 --enable-cxx --disable-shared --enable-static \
 && make -j"${MAKE_JOBS}" \
 && make install

RUN test -n "${DORKCOIN_REPO_URL}" \
 && git clone --depth 1 --branch "${DORKCOIN_REF}" --single-branch "${DORKCOIN_REPO_URL}" dorkcoin-src \
 && test "$(git -C /tmp/dorkcoin-src rev-parse HEAD)" = "${DORKCOIN_COMMIT}"

WORKDIR /tmp/dorkcoin-src
RUN ./autogen.sh \
 && mkdir -p build \
 && cd build \
 && ../configure \
     --without-gui \
     --disable-tests \
     --disable-bench \
     --disable-man \
     --enable-wallet \
     --without-miniupnpc \
 && make -j"${MAKE_JOBS}" \
 && strip --strip-unneeded \
     ./src/dorkcoind \
     ./src/dorkcoin-cli \
     ./src/dorkcoin-tx


FROM debian:trixie-slim@sha256:26f98ccd92fd0a44d6928ce8ff8f4921b4d2f535bfa07555ee5d18f61429cf0c

ARG DEBIAN_SNAPSHOT=20260406T000000Z
ARG BASH_PKG_VERSION=5.2.37-2+b8
ARG CA_CERTIFICATES_VERSION=20250419
ARG CURL_VERSION=8.14.1-2+deb13u2
ARG GOSU_VERSION=1.17-3+b4
ARG LIBEVENT_VERSION=2.1.12-stable-10+b1
ARG LIBBOOST_RUNTIME_VERSION=1.83.0-4.2
ARG LIBSQLITE3_VERSION=3.46.1-7+deb13u1
ARG LIBZMQ5_VERSION=4.3.5-1+b3
ARG LIBSSL3_VERSION=3.5.5-1~deb13u1

ENV DEBIAN_FRONTEND=noninteractive

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN rm -f /etc/apt/sources.list.d/debian.sources \
 && printf 'deb [check-valid-until=no] http://snapshot.debian.org/archive/debian/%s trixie main\n' "${DEBIAN_SNAPSHOT}" > /etc/apt/sources.list \
 && printf 'Acquire::Check-Valid-Until "false";\n' > /etc/apt/apt.conf.d/99snapshot \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
    bash="${BASH_PKG_VERSION}" \
     ca-certificates="${CA_CERTIFICATES_VERSION}" \
     curl="${CURL_VERSION}" \
     gosu="${GOSU_VERSION}" \
     libevent-2.1-7t64="${LIBEVENT_VERSION}" \
     libevent-pthreads-2.1-7t64="${LIBEVENT_VERSION}" \
     libboost-filesystem1.83.0="${LIBBOOST_RUNTIME_VERSION}" \
    libboost-chrono1.83.0t64="${LIBBOOST_RUNTIME_VERSION}" \
     libboost-program-options1.83.0="${LIBBOOST_RUNTIME_VERSION}" \
     libboost-random1.83.0="${LIBBOOST_RUNTIME_VERSION}" \
     libboost-system1.83.0="${LIBBOOST_RUNTIME_VERSION}" \
     libboost-thread1.83.0="${LIBBOOST_RUNTIME_VERSION}" \
     libsqlite3-0="${LIBSQLITE3_VERSION}" \
     libzmq5="${LIBZMQ5_VERSION}" \
     libssl3t64="${LIBSSL3_VERSION}" \
 && rm -rf /var/lib/apt/lists/*

RUN useradd -m -u 1000 -s /bin/bash dorkcoin

WORKDIR /opt/dorkcoin

COPY --from=builder --chmod=755 /tmp/dorkcoin-src/build/src/dorkcoind /usr/local/bin/dorkcoind
COPY --from=builder --chmod=755 /tmp/dorkcoin-src/build/src/dorkcoin-cli /usr/local/bin/dorkcoin-cli
COPY --from=builder --chmod=755 /tmp/dorkcoin-src/build/src/dorkcoin-tx /usr/local/bin/dorkcoin-tx

COPY --chmod=755 docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["dorkcoind"]