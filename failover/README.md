# Failover

Run the setup

```
docker-compose up
```

Curl the local endpoint, by default API resolves to local datacenter
```
$ curl localhost:9090
```

Kill the API service in DC1
```
$ docker kill failover_api_dc1_1

# Reponse from: web #
Hello World
## Called upstream uri: http://localhost:9091
  # Reponse from: api #
  API DC1
```

Curl the local endpoint, upstream request will failover to DC2 service
```
$ curl localhost:9090

# Reponse from: web #
Hello World
## Called upstream uri: http://localhost:9091
  # Reponse from: api #
  API DC2
```
