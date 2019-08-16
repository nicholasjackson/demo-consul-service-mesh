# demo-consul-service-mesh
Various demos for Consul service mesh

## Gateways
This demo highlights Consul Service Mesh gateways which allow cross cluster communication between services. It consists of the following features:
* Private Network DC1
* Private Network DC2
* WAN Network (Consul Server, Consul Gateway)
* Consul Datacenter DC1 - Primary
* Consul Datacenter DC2 - Secondary, joined to DC1 with WAN federation
* Consul Gateway DC1
* Consul Gateway DC2
* Web frontend (DC1) communicates with API in DC2 via Consul Gateways
* API service (DC2)

### Running
```
$ docker-compose up
Creating network "demo-consul-service-mesh_dc1" with driver "bridge"
Creating demo-consul-service-mesh_consul-dc2_1  ... done
Creating demo-consul-service-mesh_gateway-dc2_1 ... done
Creating demo-consul-service-mesh_api_1         ... done
Creating demo-consul-service-mesh_gateway-dc1_1 ... done
Creating demo-consul-service-mesh_consul-dc1_1  ... done
Creating demo-consul-service-mesh_web_1         ... done
Creating demo-consul-service-mesh_api_envoy_1   ... done
Creating demo-consul-service-mesh_web_envoy_1   ... done
Attaching to demo-consul-service-mesh_gateway-dc1_1, demo-consul-service-mesh_api_1, demo-consul-service-mesh_gateway-dc2_1, demo-consul-service-mesh_web_1, demo-consul-service-mesh_consul-dc2_1, demo-consul-service-mesh_consul-dc1_1, demo-consul-service-mesh_api_envoy_1, demo-consul-service-mesh_web_envoy_1
api_1          | 2019-08-16T14:44:53.916Z [INFO]  Starting service: name=web message="API V1" upstreamURIs= upstreamWorkers=1 listenAddress=localhost:9090 http_client_keep_alives=true zipkin_endpoint=
web_1          | 2019-08-16T14:44:54.102Z [INFO]  Starting service: name=web message="Hello World" upstreamURIs=http://localhost:9091 upstreamWorkers=1 listenAddress=0.0.0.0:9090 http_client_keep_alives=false zipkin_endpoint=
consul-dc2_1   | ==> Starting Consul agent...
gateway-dc2_1  | Error retrieving members: Get http://10.6.0.2:8500/v1/agent/members?segment=_all: dial tcp 10.6.0.2:8500: connect: connection refused
consul-dc1_1   | BootstrapExpect is set to 1; this is the same as Bootstrap mode.
consul-dc1_1   | bootstrap = true: do not enable unless necessary
consul-dc2_1   | BootstrapExpect is set to 1; this is the same as Bootstrap mode.
consul-dc2_1   | bootstrap = true: do not enable unless necessary
gateway-dc2_1  | Waiting for Consul to start
```

Consul in DC1 is available at `http://localhost:8500` and DC2 at `http://localhost:9500`, UI and API are accessible.

### Testing application
To test the application you can curl the web endpoint:

```
* Rebuilt URL to: localhost:9090/
*   Trying ::1...
* TCP_NODELAY set
* Connected to localhost (::1) port 9090 (#0)
> GET / HTTP/1.1
> Host: localhost:9090
> User-Agent: curl/7.54.0
> Accept: */*
>
< HTTP/1.1 200 OK
< Date: Fri, 16 Aug 2019 14:49:14 GMT
< Content-Length: 112
< Content-Type: text/plain; charset=utf-8
<
# Reponse from: web #
Hello World
## Called upstream uri: http://localhost:9091
  # Reponse from: web #
* Connection #0 to host localhost left intact
  API V1% 
```

The web application makes an upstream call to the API which resides in a separate datacenter. The full flow through the service mesh is as follows:
* Web app makes upstream app via Envoy running at localhost:9091
* Envoy forwards request to Consul Gateway in DC1
* Mesh Gateway in DC1 forwards request to Consul Gateway in DC2 Over WAN
* Mesh Gateway in DC2 forwards request to upstream Envoy for API service
* Envoy sidecar for API service forwards request to API service which is only listening on localhost
* API service receives request and sends response back through same chain
