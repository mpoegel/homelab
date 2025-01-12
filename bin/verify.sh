#!/bin/bash
set -e

envoy -c config/home_envoy.yaml --mode validate
envoy -c config/edge_envoy.yaml --mode validate

otelcol validate --config config/otel_collector.yaml
