##!/usr/bin/env bash
#Depends On: jq
#Leverage $NOMAD_ADDR variable to hit api and return total compute used via pipe sequence
#Could drop into a log file if you wanted to monitor the compute usage regularly
#example extended usage:
## linux: watch -n 10 $(pwd)/getMetrics.sh >> $(pwd)/log
## mac: while :;do clear;. $(pwd)/getMetrics.sh >> $(pwd)/log;sleep 10;done;
curl "$NOMAD_ADDR/v1/metrics" | jq .Gauges | jq .[] | jq -c | grep "alloc_bytes" | jq .Value
