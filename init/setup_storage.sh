#!/bin/bash

docker pull minio/minio
docker run -d --name minio --restart=always \
   -p 9000:9000 \
   -p 9001:9001 \
   -v /volume4/docker/minio:/data \
   -e "MINIO_ROOT_USER=matt" \
   -e "MINIO_ROOT_PASSWORD=${MINIO_PASSWORD}" \
   minio/minio server /data --console-address ":9001"
