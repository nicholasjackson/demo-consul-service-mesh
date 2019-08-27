# Traffic Splitting

## Canary Deployments
A Canary deployment is a technique for deploying a new version of a service, while avoiding downtime. During a canary deployment you shift a small percentage of traffic to a new version of a service while monitoring its behavior. Initially you send the smallest amount of traffic possible to the new service while still generating meaningful performance data. As you gain confidence in the new version you slowly increase the proportion of traffic it handles. Eventually, the canary version handles 100% of all traffic, at which point the old version can be completely deprecated and then removed from the environment.

The new version of the service is called the canary version, as a reference to the “canary in a coal mine”.

To determine the correct function of the new service, you must have observability into your application. Metrics and tracing data will allow you to determine that the new version is working as expected and not throwing errors. In contrast to Blue/Green deployments, which involve transitioning to a new version of a service in a single step, Canary deployments take a more gradual approach, which helps you guard against service errors that only manifest themselves with a particular load.

## Environment
The demo architecture you’ll use consists of 3 services, a public Web service, two versions of the API service, and a Consul server. The services make up a two-tier application; the Web service accepts incoming traffic and makes an upstream call to API service. You’ll imagine that version 1 of the API service is already running in production and handling traffic, and that version 2 contains some changes you want to ship in a canary deployment.
![Consul Traffic splitting](https://www.datocms-assets.com/2885/1564774258-l7routing1.png)

To deploy version 2 of your API service, you will:
1. Start an instance of the v2 API service in your production environment.
2. Set up a traffic split to make sure v2 doesn’t receive any traffic at first.
3. Register v2 so that Consul can send traffic to it.
4. Slowly shift traffic to v2 and a way from v1 until the new version is handling all the traffic.

## Starting the Demo Environment

```shell
$ docker-compose up

Creating consul-demo-traffic-splitting_api_v1_1    ... done
Creating consul-demo-traffic-splitting_consul_1 ... done
Creating consul-demo-traffic-splitting_web_1    ... done
Creating consul-demo-traffic-splitting_web_envoy_1    ... done
Creating consul-demo-traffic-splitting_api_proxy_v1_1 ... done
Attaching to consul-demo-traffic-splitting_consul_1, consul-demo-traffic-splitting_web_1, consul-demo-traffic-splitting_api_v1_1, consul-demo-traffic-splitting_web_envoy_1, consul-demo-traffic-splitting_api_proxy_v1_1
```

The following services will automatically start in your local Docker environment and register with Consul.
Consul Server
Web service with Envoy sidecar
API service version 1 with Envoy sidecar

You can see Consul’s configuration in the `consul_config` folder, and the service definitions in the `service_config` folder.

Once everything is up and running, you can view the health of the registered services by looking at the Consul UI at `http://localhost:8500`. All services should be passing their health checks.

![](https://www.datocms-assets.com/2885/1564774263-l7routing2.png)

Curl the Web endpoint to make sure that the whole application is running. You will see that the Web service gets a response from version 1 of the API service.

```shell
$ curl localhost:9090
Hello World
###Upstream Data: localhost:9091###
  Service V1%
```

Initially, you will want to deploy version 2 of the API service to production without sending any traffic to it, to make sure that it performs well in a new environment. Prevent traffic from flowing to version 2 when you register it, you will preemptively set up a  traffic split to send 100% of your traffic to version 1 of the API service, and 0% to the not-yet-deployed version 2. Splitting the traffic makes use of the new Layer 7 features built into Consul Service Mesh.

## Configuring Traffic Splitting
Traffic Splitting uses configuration entries (introduced in Consul 1.5 and 1.6) to centrally configure the services and Envoy proxies. There are three configuration entries you need to create to enable traffic splitting:
Service Defaults for the API service to set the protocol to HTTP.
Service Splitter which defines the traffic split between the service subsets.
Service Resolver which defines which service instances are version 1 and  2.
### Configuring Service Defaults
Traffic splitting requires that the upstream application uses HTTP, because splitting happens on layer 7 (on a request by request basis). You will tell Consul that your upstream service uses HTTP by setting the protocol in a “service defaults” configuration entry for the API service. This configuration is already in your demo environment at `l7_config/api_service_defaults.json`. It  looks like this.

```json
{
  "kind": "service-defaults",
  "name": "api",
  "protocol": "http"
}
```

The `kind` field denotes the type of configuration entry which you are defining; for this example, `service-defaults`. The `name` field defines which service the service-defaults configuration entry applies to. (The value of this field must match the name of a service registered in Consul, in this example, `api`.) The `protocol` is `http`.

To apply the configuration, you can either use the Consul CLI or the API. In this example we’ll use the configuration entry endpoint of the HTTP API, which  is available at `http://localhost:8500/v1/config`. To apply the config, use a PUT operation in the following  command.

```shell
$ curl localhost:8500/v1/config -XPUT -d @l7_config/api_service_defaults.json
true%
```

For more information on service-defaults configuration entries, see the [documentation](https://www.consul.io/docs/agent/config-entries/service-defaults.html)

### Configuring the Service Resolver
The next configuration entry you need to add is the Service Resolver, which allows you to define how Consul’s service discovery selects service instances for a given service name.

Service Resolvers allow you to filter for subsets of services based on information in the service registration. In this example, we are going to define the subsets “v1” and “v2” for the API service, based on its registered metadata. API service version 1 in the demo is already registered with the tags `v1` and service metadata `version:1`. When you register version 2 you will give it the tag `v2` and the metadata `version:2`. The `name` field is set to the name of the service in the Consul service catalog.

The service resolver is already in your demo environment at `l7_config/api_service_resolver.json` and it looks like this.

```json
{
  "kind": "service-resolver",
  "name": "api",

  "subsets": {
    "v1": {
      "filter": "Service.Meta.version == 1"
    },
    "v2": {
      "filter": "Service.Meta.version == 2"
    }
  }
}
```

Apply the service resolver configuration entry using the same method you used in the previous example.

```shell
$ curl localhost:8500/v1/config -XPUT -d @l7_config/api_service_resolver.json
true% 
```

For more information about service resolvers see the [documentation](https://www.consul.io/docs/agent/config-entries/service-resolver.html).
### Configure Service Splitting - 100% of traffic to Version 1

Next, you’ll create a configuration entry that will split percentages of traffic to the subsets of your upstream service that you just defined. Initially, you want the splitter to send all traffic to v1 of your upstream service, which prevents any traffic from being sent to v2 when you register it. In a production scenario, this would give you time to make sure that v2 of your service is up and running as expected before sending it any real traffic.

The configuration entry for Service Splitting is of `kind` of `service-splitter`. Its `name` specifies which service that the splitter will act on. The `splits` field takes an array which defines the different splits; in this example, there are only two splits; however, it is possible to configure more complex scenarios. Each split has a weight which defines the percentage of traffic to distribute to each service subset. The total weights for all splits must equal 100. For our initial split, we are going to configure all traffic to be directed to the service subset v1.

The service splitter configuration already exists in your demo environment at `l7_config/api_service_splitter_100_0.json` and looks like this.  

```json
{
  "kind": "service-splitter",
  "name": "api",
  "splits": [
    {
      "weight": 100,
      "service_subset": "v1"
    },
    {
      "weight": 0,
      "service_subset": "v2"
    }
  ]
}
```

Apply this configuration entry by issuing another PUT request to the Consul’s configuration entry endpoint of the HTTP API.

```shell
$ curl localhost:8500/v1/config -XPUT -d @l7_config/api_service_splitter_100_0.json
true%
``` 

This scenario is the first stage in our Canary deployment; you can now launch the new version of your service without it immediately being used by the upstream load balancing group. 

### Start and Register API Service Version 2

Next you’ll start the canary version of the API service (version 2),  and register it with the settings that you used in the configuration entries for resolution and splitting. Start the service, register it, and start its connect sidecar with the following command. This command will run in the foreground, so you’ll need to open a new terminal window after you run it.

```shell
$ docker-compose -f docker-compose-v2.yml up
```

Check that the service and its proxy have registered by looking for a new `v2` tags next to the API service and API sidecar proxies in the Consul UI.  

### Configure Service Splitting - 50% Version 1, 50% Version 2
Now that version 2 is running and registered, the next step is to gradually increase traffic to it by changing the weight of the v2 service subset in the service splitter configuration. Let’s increase the weight of the v2 service to 50%. Remember; total service weight must equal 100, so you also reduce the weight of the v1 subset to 50. The configuration file is already in your demo environment at `l7_config/api_service_splitter_50_50.json` and it looks like this.

```json
{
  "kind": "service-splitter",
  "name": "api",
  "splits": [
    {
      "weight": 50,
      "service_subset": "v1"
    },
    {
      "weight": 50,
      "service_subset": "v2"
    }
  ]
}
```

Apply the configuration as before.

```shell
$ curl localhost:8500/v1/config -XPUT -d @l7_config/api_service_splitter_50_50.json
true%
```

Now that you’ve increased the percentage of traffic to v2, curl the web service again. You will see traffic equally distributed across both of the service subsets.

```shell
$ curl localhost:9090
Hello World
###Upstream Data: localhost:9091###
  Service V1%                                                                                            
$ curl localhost:9090
Hello World
###Upstream Data: localhost:9091###
  Service V2%                                                                                            
$ curl localhost:9090
Hello World
###Upstream Data: localhost:9091###
  Service V1% 
```

If you were actually performing a canary deployment you would want to choose a much smaller percentage for your initial split: the smallest possible percentage that would give you reliable data on service performance. You would then slowly increase the percentage by iterating over this step as you gained confidence in version 2 of your service. Some companies may eventually choose to automate the ramp up based on preset performance thresholds. 

### Configure Service Splitting - 100% Version 2
Once you are confident that the new version of the service is operating correctly, you can send 100% of traffic to the version 2 subset. The configuration for a 100% split to version 2 looks like this.

```json
{
  "kind": "service-splitter",
  "name": "api",
  "splits": [
    {
      "weight": 0,
      "service_subset": "v1"
    },
    {
      "weight": 100,
      "service_subset": "v2"
    }
  ]
}
```

Apply it with a call to the HTTP API `config` endpoint as you did before.

```shell
$ curl localhost:8500/v1/config -XPUT -d @l7_config/api_service_splitter_0_100.json
true%
```

Now when you curl the web service again. 100% of traffic is sent to the version 2 subset.

```shell
$ curl localhost:9090
Hello World
###Upstream Data: localhost:9091###
  Service V2%                                                                                            
$ curl localhost:9090
Hello World
###Upstream Data: localhost:9091###
  Service V2%                                                                                            
$ curl localhost:9090
Hello World
###Upstream Data: localhost:9091###
  Service V2%
```

Typically in a production environment, you would now remove the version 1 service to release capacity in your cluster. Congratulations, you’ve now completed the deployment of version 2 of your service. 

## Clean up

To stop and remove the containers and networks that you created you will run `docker-compose down` twice: once for each of the docker compose commands you ran. Because containers you created in the second compose command are running on the network you created in the first command, you will need to bring down the environments in the opposite order that you created them in.

First you’ll stop and remove the containers created for v2 of the API service.

```shell
$ docker-compose -f docker-compose-v2.yml down
Stopping consul-demo-traffic-splitting_api_proxy_v2_1 ... done
Stopping consul-demo-traffic-splitting_api_v2_1       ... done
WARNING: Found orphan containers (consul-demo-traffic-splitting_api_proxy_v1_1, consul-demo-traffic-splitting_web_envoy_1, consul-demo-traffic-splitting_consul_1, consul-demo-traffic-splitting_web_1, consul-demo-traffic-splitting_api_v1_1) for this project. If you removed or renamed this service in your compose file, you can run this command with the --remove-orphans flag to clean it up.
Removing consul-demo-traffic-splitting_api_proxy_v2_1 ... done
Removing consul-demo-traffic-splitting_api_v2_1       ... done
Network consul-demo-traffic-splitting_vpcbr is external, skipping
```

Then, you’ll stop and remove the containers and the network that you created in the first docker compose command. 

```shell
$ docker-compose down
Stopping consul-demo-traffic-splitting_api_proxy_v1_1 ... done
Stopping consul-demo-traffic-splitting_web_envoy_1    ... done
Stopping consul-demo-traffic-splitting_consul_1       ... done
Stopping consul-demo-traffic-splitting_web_1          ... done
Stopping consul-demo-traffic-splitting_api_v1_1       ... done
Removing consul-demo-traffic-splitting_api_proxy_v1_1 ... done
Removing consul-demo-traffic-splitting_web_envoy_1    ... done
Removing consul-demo-traffic-splitting_consul_1       ... done
Removing consul-demo-traffic-splitting_web_1          ... done
Removing consul-demo-traffic-splitting_api_v1_1       ... done
Removing network consul-demo-traffic-splitting_vpcbr
```
## Summary

In this blog, we walked you through the steps required to perform Canary deployments using traffic splitting and resolution. For more in-depth information on Canary deployments, Danilo Sato has written an [excellent article](https://martinfowler.com/bliki/CanaryRelease.html) on Martin Fowler's website. 

The advanced L7 traffic management in 1.6.0 is not limited to splitting. It also includes HTTP based routing and new settings for service resolution. In combination, these features enable sophisticated traffic routing and service failover. All the new L7 traffic management settings can be found in the [documentation](https://www.consul.io/docs/connect/l7-traffic-management.html). If you’d like to go farther, combine it with our guide on and [L7 Observability](https://learn.hashicorp.com/consul/developer-mesh/l7-observability-k8s) to implement some of the monitoring needed for new service deployments. 

Please keep in mind that [Consul 1.6 RC](https://www.consul.io/downloads.html) isn’t suited for production deployments. We’d appreciate any feedback or bug reports you have in our [GitHub issues](https://github.com/hashicorp/consul/issues), and you’re welcome to ask questions in our new [community forum](https://discuss.hashicorp.com/c/consul).

# Consul Service Mesh - Example using Service Splitting

## Running the application

## Configuring service splitting 100% api version 1

## Configure service splitting 50% api version 1, 50% api version 2
