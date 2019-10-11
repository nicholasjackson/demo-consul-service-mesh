# Traffic splitting on K8s with Consul Connect
This example shows how to split traffic between two versions of a service in Kubernetes

![](/images/traffic_split_6.png)

If you do not have access to a Kubernetes cluster, the script in [../consul_k8s](../consul_k8s) allows you to create
a Kubernetes cluster with Consul installed using Docker on your local machine.

## Configuring Helm

To enable Consul Service Mesh the following values must be configured in the official helm chart:

```
global
  image: "consul:1.6.1"
  imageK8S:  "hashicorp/consul-k8s:0.9.2"

connectInject:
  enabled: true
  imageEnvoy: "envoyproxy/envoy:v1.10.0"
  
  centralConfig:
    enabled: true

client:
  enabled: true
  grpc: true
```

## L7 configuration
To enable traffic splitting the following configuration needs to be set:

### `service-defaults` for web service setting HTTP protocol

```
kind = "service-defaults"
name = "web"
protocol = "http"
```

### `service-defaults` for api service setting HTTP protocol

```
kind = "service-defaults"
name = "api"
protocol = "http"
```

### `service-resolver` for api service allowing subset based on service catalog metadata

```
kind = "service-resolver"
name = "api"

# Filtering options for subsets can be found at the following link
# https://www.consul.io/api/health.html#filtering-2

# Using a default_subset will route traffic to the subset specified in the value when no `traffic-splitter` is present. 
# Configuring the `traffic-splitter` overrides this default.
default_subset = "v1"

subsets = {
  v1 = {
    filter = "Service.Meta.version == 1"
  }
  v2 = {
    filter = "Service.Meta.version == 2"
  }
}
```

### `service-splitter` to configure percentage of traffic which is sent to each subset.
The following example splits traffic 50/50 between both subsets

```
kind = "service-splitter",
name = "api"

splits = [
  {
    weight = 50,
    service_subset = "v1"
  },
  {
    weight = 50,
    service_subset = "v2"
  }
]
```

### Loading configuration

To load the configuration into Consul it is possible to use three methods:
* Consul CLI `consul config write file.hcl`, hcl or json formatted files
* PUT request to the API (json only)
* Using a Kubernetes job

The following example shows how it is possible to use a Kubernetes job to set multiple configuration files. There are 
updates to the K8s integration which will remove the need for the job and will allow a config map to be referenced by
K8s annotation and automatically injected.

```
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: central-config-split
data:
  1_web_defaults.hcl: |
    kind = "service-defaults"
    name = "web"
    protocol = "http"
  2_api_defaults.hcl: |
    kind = "service-defaults"
    name = "api"
    protocol = "http"
  3_api_resolver.hcl: |
    kind = "service-resolver"
    name = "api"

    # https://www.consul.io/api/health.html#filtering-2
    # # Show Node.Meta demonstration showing performance testing a new instance type
    default_subset = "v1"

    subsets = {
      v1 = {
        filter = "Service.Meta.version == 1"
      }
      v2 = {
        filter = "Service.Meta.version == 2"
      }
    }

---
apiVersion: batch/v1
kind: Job
metadata:
  name: central-config-split
  labels:
    app: central-config-split
spec:
  template:
    spec:
      restartPolicy: Never
      volumes:
      - name: central-config
        configMap:
          name: central-config-split
      containers:
      - name: central-config-split
        image: "nicholasjackson/consul-envoy:v1.6.1-v0.10.0"
        imagePullPolicy: Always
        env:
        - name: "CONSUL_HTTP_ADDR"
          value: "consul-consul-server:8500"
        - name: "CONSUL_GRPC_ADDR"
          value: "consul-consul-server:8502"
        - name: "CENTRAL_CONFIG_DIR"
          value: "/config"
        volumeMounts:
        - name: "central-config"
          readOnly: true
          mountPath: "/config"
```

### Configuring metadata
For the previous `service-resolver` to include a service in a particular subset, Consul MetaData is used.
Configuring the metadata for the service in Consul`s service catalog is done by using the K8s annotations, e.g.

```
  template:
    metadata:
      labels:
        app: api-v1
      annotations:
        "consul.hashicorp.com/connect-inject": "true"
        "consul.hashicorp.com/service-meta-version": "1"
        "consul.hashicorp.com/service-tags": "v1"
```


## Running the example

With a running Kubernetes cluster and the Consul Helm chart installed a simple 2 tier application can be run using the following command:

```
➜ kubectl apply -f traffic_split.yml
configmap/central-config-split created
job.batch/central-config-split created
service/web-service created
deployment.apps/web-deployment created
deployment.apps/api-deployment-v1 created
deployment.apps/api-deployment-v2 created
```

This config contains the following elements
* Web application - entry point
* API version 1 - upstream service
* API version 2 - upstream service
* K8s Service pointed at Web application
* Config map containing L7 config
* Job to load L7 config

It should take a couple of seconds for the application to get up and running:

```
➜ kubectl get svc
NAME                                 TYPE           CLUSTER-IP     EXTERNAL-IP     PORT(S)                                                                   AGE
consul-consul-connect-injector-svc   ClusterIP      10.0.157.120   <none>          443/TCP                                                                   2d4h
consul-consul-dns                    ClusterIP      10.0.156.52    <none>          53/TCP,53/UDP                                                             2d4h
consul-consul-server                 ClusterIP      None           <none>          8500/TCP,8301/TCP,8301/UDP,8302/TCP,8302/UDP,8300/TCP,8600/TCP,8600/UDP   2d4h
consul-consul-ui                     ClusterIP      10.0.175.50    <none>          80/TCP                                                                    2d4h
kubernetes                           ClusterIP      10.0.0.1       <none>          443/TCP                                                                   2d4h
web-service                          LoadBalancer   10.0.108.23    13.64.193.176   80:32195/TCP                                                              41m
```

You can access the Kubernetes service by using the command `kubectl port-forward` to forward a port from your local
machine to the service for the web application in your Kubernetes cluster.

```
kubectl port-forward svc/web-service 9090
Forwarding from 127.0.0.1:9090 -> 9090
Forwarding from [::1]:9090 -> 9090
```

The web service can then be accessed at `http://localhost:9090`. When the web service is called it will make an upstream call
to the API service. You should see the following output in your terminal.

```
➜ curl  localhost:9090
{
  "name": "web",
  "type": "HTTP",
  "duration": "6.137322ms",
  "body": "Hello World",
  "upstream_calls": [
    {
      "name": "api-v1",
      "uri": "http://localhost:9091",
      "type": "HTTP",
      "duration": "10.9µs",
      "body": "Response from API v1"
    }
  ]
}
```

Since there is no `traffic-splitter` configured the service will always resolve to the default subset which is the `v1` api

To enable traffic splitting apply the central config to consul using the CLI

```
➜ consul config write 1_api-splitter.hcl
```

Now when the web endpoint is curled traffic will be split between `v1` and `v2`

```
➜ curl http://localhost:9090
{
  "name": "web",
  "type": "HTTP",
  "duration": "10.967173ms",
  "body": "Hello World",
  "upstream_calls": [
    {
      "name": "api-v1",
      "uri": "http://localhost:9091",
      "type": "HTTP",
      "duration": "10.3µs",
      "body": "Response from API v1"
    }
  ]
}

➜ curl http://localhost:9090
{
  "name": "web",
  "type": "HTTP",
  "duration": "10.151383ms",
  "body": "Hello World",
  "upstream_calls": [
    {
      "name": "api-v2",
      "uri": "http://localhost:9091",
      "type": "HTTP",
      "duration": "143.298µs",
      "body": "Response from API v2"
    }
  ]
}
```

Changing the weighting of the `service-splitter` and reapplying tthe config will imediately update the system, for example
to configure 100% traffic to `v2`. Modify the `1_api_splitter.hcl` file with the following values:

```

kind = "service-splitter",
name = "api"

splits = [
  {
    weight = 0,
    service_subset = "v1"
  },
  {
    weight = 100,
    service_subset = "v2"
  }
]
```

Again write the config to Consul:

```
consul config write 1_api_splitter.hcl
```

Curling the endpoint will now only show the v2 API as an upstream:

```
➜ curl http://localhost:9090
{
  "name": "web",
  "type": "HTTP",
  "duration": "10.151383ms",
  "body": "Hello World",
  "upstream_calls": [
    {
      "name": "api-v2",
      "uri": "http://localhost:9091",
      "type": "HTTP",
      "duration": "143.298µs",
      "body": "Response from API v2"
    }
  ]
}

➜ curl http://localhost:9090
{
  "name": "web",
  "type": "HTTP",
  "duration": "10.151383ms",
  "body": "Hello World",
  "upstream_calls": [
    {
      "name": "api-v2",
      "uri": "http://localhost:9091",
      "type": "HTTP",
      "duration": "143.298µs",
      "body": "Response from API v2"
    }
  ]
}
```