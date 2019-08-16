#!/bin/sh

DOCKER_HOST=$(getent hosts host.docker.internal | awk '{ print $1 }')

# Update the consul config with the advertise address
sed "s/##WAN_ADDR##/${DOCKER_HOST}/g" /templates/consul-dc1.hcl > /consul_config/consul-dc1.hcl	
sed "s/##WAN_ADDR##/${DOCKER_HOST}/g" /templates/consul-dc2.hcl > /consul_config/consul-dc2.hcl	

tail -f /dev/null &
PID=$!
wait $PID
