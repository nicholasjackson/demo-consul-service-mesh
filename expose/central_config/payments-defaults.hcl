# Requires Consul 1.6.2

Kind = "service-defaults"
Name = "payments"

Protocol = "http"

MeshGateway = {
  mode = "local"
}

Expose = {
  Paths = [
    {
      Path = "/health"
      LocalPathPort = 9090
      ListenerPort = 9091
    }
  ]
}