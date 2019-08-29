# Traffic Routing
This example demonstrates how to configure path based routing for upstream services.

![](traffic_routing/images/routing.png)

## Configuration
The API upstream called by the Web service is configured to route based on two different paths `\v1` which points to `api_v1` and `\v2` which points to `api_v2`. To configure this in Consul Service Mesh the following central configuration is required:
* Service Router - API Service
* Service Defaults - Web Service
* Service Defaults - API V1
* Service Defaults - API V2

### Service Router - API Service
```
kind = "service-router"
name = "api"
routes = [
  {
    match {
      http {
        path_prefix = "/v1"
      }
    }

    destination {
      service = "api-v1"
    }
  },
  {
    match {
      http {
        path_prefix = "/v2"
      }
    }

    destination {
      service = "api-v2"
    }
  },
]
```

### service defaults - web
```
kind = "service-defaults"
name = "web"

protocol = "http"

meshgateway = {
  mode = "local"
}
```

### service defaults - api-v1
```
kind = "service-defaults"
name = "api-v"

protocol = "http"

meshgateway = {
  mode = "local"
}
```

### service defaults - api-v2
```
kind = "service-defaults"
name = "api-v2"

protocol = "http"

meshgateway = {
  mode = "local"
}
```

## Running the setup
The demo app can be started using Docker Compose, this will expose the web app at `localhost:9090`
```
➜ docker-compose up
Starting traffic_routing_web_1          ... done
Starting traffic_routing_api_v2_1 ... done
Starting traffic_routing_consul_1       ... done
Starting traffic_routing_api_v1_1       ... done
Starting traffic_routing_api_proxy_v2_1 ... done
Starting traffic_routing_web_envoy_1    ... done
Starting traffic_routing_api_proxy_v1_1 ... done
Attaching to traffic_routing_api_v2_1, traffic_routing_consul_1, traffic_routing_web_1, traffic_routing_api_v1_1, traffic_routing_api_proxy_v2_1, traffic_routing_web_envoy_1, traffic_routing_api_proxy_v1_1
api_v2_1        | 2019-08-29T12:00:39.132Z [INFO]  Starting service: name=api message="API V2" upstreamURIs= upstreamWorkers=1 listenAddress=localhost:9090 http_client_keep_alives=true http_append_request=true service type=http zipkin_endpoint=
consul_1        | BootstrapExpect is set to 1; this is the same as Bootstrap mode.
```

## Testing path based routing
Since the route for the V1 API service is mapped at the path `/v1` you can simply curl the web endpoint with this path, you will see the response from the V1 API

```
➜ curl localhost:9090/v1
# Reponse from: web #
Hello World
## Called upstream uri: http://localhost:9091
  # Reponse from: api #
  API V1
  % 
```

Changing the path to `/v2` and again curling the service will return the response from the V2 API
```
➜ curl localhost:9090/v2
# Reponse from: web #
Hello World
## Called upstream uri: http://localhost:9091
  # Reponse from: api #
  API V2
  % 
```
