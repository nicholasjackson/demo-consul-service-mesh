up:
	# set the wan address in the config file
	sed 's/##WAN_ADDR##/192.168.87.154/g' templates/consul-dc1.hcl > consul_config/consul-dc1.hcl	
	sed 's/##WAN_ADDR##/192.168.87.154/g' templates/consul-dc2.hcl > consul_config/consul-dc2.hcl	
	docker-compose up

down:
	docker-compose down
