data_dir = "/tmp/"
log_level = "DEBUG"
server = true

bootstrap_expect = 1
ui = true

bind_addr = "0.0.0.0"
client_addr = "0.0.0.0"

connect {
  enabled = true
}

ports {
  grpc = 8502
}

enable_central_service_config = true
