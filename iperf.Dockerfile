MAINTAINER Jakob Möller <jmoller@redhat.com>
FROM registry.access.redhat.com/ubi9/ubi-minimal:latest as builder

RUN microdnf update -y
RUN microdnf install -y git autoconf automake make gcc glibc-static libtool zlib openssl-libs perl

ARG OPENSSL_VERSION="3.2.1"
RUN git clone --depth=1 --branch openssl-$OPENSSL_VERSION "git://git.openssl.org/openssl.git" /tmp/openssl
WORKDIR /tmp/openssl
RUN ./config --prefix="$HOME/openssl" --openssldir="$HOME/openssl" no-shared no-dso
RUN make -j$(nproc)
RUN make install_sw install_ssldirs

ARG IPERF3_VERSION="3.16"
RUN git clone --depth=1 --branch $IPERF3_VERSION "https://github.com/esnet/iperf.git" /tmp/iperf
WORKDIR /tmp/iperf
RUN ./bootstrap.sh
RUN ./configure --disable-shared --enable-static --enable-static-bin --prefix="$HOME/iperf3"
RUN make -j$(nproc)
RUN make install

RUN $HOME/iperf3/bin/iperf3 --version
RUN cp $HOME/iperf3/bin/iperf3 /usr/local/bin/iperf3

FROM registry.access.redhat.com/ubi9/ubi-micro:latest

COPY --from=builder /usr/local/bin/iperf3 /usr/local/bin/iperf3

EXPOSE 5201

ENTRYPOINT ["iperf3"]