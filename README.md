# Consul Service Mesh Demos using Docker-Compose
This repository contains various demonstrations to highlight features and configuration in Consul Service Mesh.

## [Traffic Shifting](traffic_split/)
This demonstration shows how traffic can be split between two service instances. This feature could be used for a Canary or Dark deployment testing strategy.

![](traffic_split/images/shifting_1.png)

## [Traffic Routing](traffic_routing/)
This demonstration shows how upstream traffic can be routed between two services using HTTP paths.

![](traffic_routing/images/routing.png)

## [Metrics / Tracing](metrics_tracing/)
This demonstration shows how to configure Consul Service Mesh for Observability.


## [Service Failover](failover/)
This demonstration shows how to failover upstream services to a different datacenter. This feature could be used to main uptime during a partial or regional service outage.

![](failover/images/failover.png)

## [Consul Gateways](gateways/)
This demonstration shows how to route traffic to a second Consul Datacenter using Consul Gateways. This feature could be used to route traffic between Virtual Machines and Kubernetes.

![](gateways/images/gateways.png)
