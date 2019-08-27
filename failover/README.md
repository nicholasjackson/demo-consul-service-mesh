# Failover
This example shows how DC failover works with Consul service mesh. 

The setup contains two Consul datacenters federated together and connected using Consul Gateways. Both DC1 and DC2 contain instances of the API service, under normal operating conditions the 
Web service will always use it's local instance of the API service. In the instance that there are no healthy instances of API in DC1 traffic will automatically be routed to the second datacenter.

Components:
* Private Network DC1
* Private Network DC2
* WAN Network (Consul Server, Consul Gateway)
* Consul Datacenter DC1 - Primary
* Consul Datacenter DC2 - Secondary, joined to DC1 with WAN federation
* Consul Gateway DC1
* Consul Gateway DC2
* Web frontend (DC1) communicates with API in DC1 by default, fails over to DC2
* API service (DC1)
* API service (DC2)

![](images/failover.png)

## Configuration
To enable failover the following central configuraion is required:
* Service-Defaults for Web service
* Service-Defaults for API service
* Service-Resolver for API service

### Service-Defaults - Web
```
Kind = "service-defaults"
Name = "web"

Protocol = "http"

MeshGateway = {
  mode = "local"
}
```

### Service-Defaults - API
```
Kind = "service-defaults"
Name = "api"

Protocol = "http"

MeshGateway = {
  mode = "local"
}
```

### Service-Resolver - API
```
kind     = "service-resolver"
name     = "api"

failover = {
  "*" = {
    datacenters = ["dc2"]
  }
}
```

## Running the setup
You can run the setup using the following command:
```
$ docker-compose up
Creating network "failover_dc1" with driver "bridge"
Creating network "failover_wan" with driver "bridge"
Creating network "failover_dc2" with driver "bridge"
Creating failover_gateway-dc1_1   ... done
Creating failover_gateway-dc2_1   ... done
Creating failover_consul-dc2_1    ... done
Creating failover_api_dc1_1       ... done
Creating failover_consul-dc1_1    ... done
Creating failover_api_dc2_1     ... done
Creating failover_web_1         ... done
Creating failover_web_envoy_1     ... done
Creating failover_api_envoy_dc2_1 ... done
Creating failover_api_envoy_dc1_1 ... done
Attaching to failover_web_1, failover_api_dc2_1, failover_api_dc1_1, failover_gateway-dc2_1, failover_web_envoy_1, failover_gateway-dc1_1, failover_api_envoy_dc2_1, failover_api_envoy_dc1_1, failover_consul-dc1_1, failover_consul-dc2_1
web_1            | 2019-08-27T11:19:52.425Z [INFO]  Starting service: name=web message="Hello World" upstreamURIs=http://localhost:9091 upstreamWorkers=1 listenAddress=0.0.0.0:9090 http_client_keep_alives=false service type=http zipkin_endpoint=
web_1            | 2019-08-27T11:19:52.902Z [INFO]  Handling request: request="GET / HTTP/1.1
web_1            | Host: localhost:9090
web_1            | user-agent: curl/7.54.0
web_1            | accept: */*"
web_1            | 2019-08-27T11:19:52.902Z [ERROR] Error obtaining context, creating new span: error="opentracing: SpanContext not found in Extract carrier"
web_1            | 2019-08-27T11:19:52.903Z [INFO]  Calling upstream HTTP service: uri=http://localhost:9091
api_dc2_1        | 2019-08-27T11:19:52.450Z [INFO]  Starting service: name=api message="API DC2" upstreamURIs= upstreamWorkers=1 listenAddress=localhost:9090 http_client_keep_alives=true service type=http zipkin_endpoint=
```

## Testing failover
Curl the local endpoint, by default API resolves to local datacenter

```
$ curl localhost:9090

# Reponse from: web #
Hello World
## Called upstream uri: http://localhost:9091
  # Reponse from: api #
  API DC1
```

Kill the API service in DC1

```
$ docker kill failover_api_dc1_1
```

Curl the local endpoint again, upstream requests will failover to the DC2 API service, it may take a few seconds for the health checks to fail for the DC1 API instance. Transient failures while the system is failing over to the second DC could be mitigated with retries (Demo coming soon).

```
$ curl localhost:9090

# Reponse from: web #
Hello World
## Called upstream uri: http://localhost:9091
  # Reponse from: api #
  API DC2
```
