FROM ubuntu

RUN apt update
RUN apt install -y wget

ARG ENVOY_VERSION="1.32.3"
RUN wget https://github.com/envoyproxy/envoy/releases/download/v${ENVOY_VERSION}/envoy-${ENVOY_VERSION}-linux-x86_64 \
    -O /usr/local/bin/envoy-${ENVOY_VERSION} && \
    chmod 771 /usr/local/bin/envoy-${ENVOY_VERSION} && \
    ln -s /usr/local/bin/envoy-${ENVOY_VERSION} /usr/local/bin/envoy

RUN mkdir -p /etc/letsencrypt/live/poegel.dev/ && \
    mkdir -p /etc/letsencrypt/live/oldno.name/
RUN openssl req -x509 -newkey rsa:2048 \
    -keyout /etc/letsencrypt/live/poegel.dev/privkey.pem \
    -out /etc/letsencrypt/live/poegel.dev/fullchain.pem -sha256 -days 365 \
    -nodes -subj "/C=US/ST=NewYork/L=NewYork/O=Homelab/OU=Homelab/CN=HomelabTest"
RUN openssl req -x509 -newkey rsa:2048 \
    -keyout /etc/letsencrypt/live/oldno.name/privkey.pem \
    -out /etc/letsencrypt/live/oldno.name/fullchain.pem -sha256 -days 365 \
    -nodes -subj "/C=US/ST=NewYork/L=NewYork/O=Homelab/OU=Homelab/CN=HomelabTest"

ARG OTELCOL_VERSION="0.117.0"
RUN wget https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v${OTELCOL_VERSION}/otelcol-contrib_${OTELCOL_VERSION}_linux_amd64.tar.gz \
    -O /tmp/${OTELCOL_VERSION}.tar.gz && \
    tar zxvf /tmp/${OTELCOL_VERSION}.tar.gz && \
    mv otelcol-contrib /usr/local/bin/otelcol-contrib-${OTELCOL_VERSION} && \
    ln -s /usr/local/bin/otelcol-contrib-${OTELCOL_VERSION} /usr/local/bin/otelcol

WORKDIR /workarea
