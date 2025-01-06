#!/bin/bash

# https://grafana.com/docs/grafana/latest/setup-grafana/installation/docker/
docker pull grafana/grafana-enterprise:11.4.0
docker volume create grafana-storage

docker run -d -p 3000:3000 --volume grafana-storage:/var/lib/grafana \
    --restart=always \
    --name=grafana grafana/grafana-enterprise:11.4.0

# https://grafana.com/docs/loki/latest/send-data/otel/
docker pull grafana/loki:3.3.2
docker volume create loki-storage
docker run -d --name=loki -p 3100:3100 -p 9095:9095 \
    --volume /usr/local/etc/loki-config.yaml:/etc/loki/local-config.yaml \
    --volume loki-storage=/loki \
    grafana/loki:3.3.2
