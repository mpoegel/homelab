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
    --restart=always \
    --volume /usr/local/etc/loki-config.yaml:/etc/loki/local-config.yaml \
    --volume loki-storage=/loki \
    grafana/loki:3.3.2

# https://docs.influxdata.com/influxdb3/core/install/#docker-image
docker pull influxdb:3-core
docker run -d --name=influxdb3 -p 8181:8181 influxdb:3-core influxdb3 serve \
  --node-id ${HOSTNAME} \
  --object-store s3 \
  --bucket influxdb \
  --aws-access-key-id ${OBJECT_STORE_ACCESS_KEY_ID} \
  --aws-secret-access-key ${OBJECT_STORE_SECRET_ACCESS_KEY} \
  --aws-endpoint http://green-giant:9000 \
  --aws-allow-http
