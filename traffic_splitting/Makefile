deploy_config:
	curl -XPUT -d @l7_config/api_service_defaults.json http://localhost:8500/v1/config 
	curl -XPUT -d @l7_config/api_service_resolver.json http://localhost:8500/v1/config 
	curl -XPUT -d @l7_config/api_service_splitter_100_0.json http://localhost:8500/v1/config 

update_config_50_50:
	curl -XPUT -d @l7_config/api_service_splitter_50_50.json http://localhost:8500/v1/config 

update_config_0_100:
	curl -XPUT -d @l7_config/api_service_splitter_0_100.json http://localhost:8500/v1/config 
