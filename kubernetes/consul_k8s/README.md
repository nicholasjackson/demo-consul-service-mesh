# Consul & Kubernetes using Docker
This folder contains a simple script to run a local version of Kubernetes and Consul in Docker. Kubernetes is run inside
a Docker container using `Kind` an official Kubernetes tool designed for testing Kubernetes and applications which 
support it.

Creating a fresh Kuberntes cluster and Installing Consul takes approximately 2 minutes.

The script will:
* Create an official development version of Kubernetes running in Docker
* Install Consul using the official Helm chart with sane defaults
* Expose Consul at http://localhost:8500

## Requirements
The following tools is needed to spin up this environment.
* docker (https://docs.docker.com/install/)

## Recommended tools
The following tools are recommended but not essential.
* Consul CLI [https://releases.hashicorp.com/consul/](https://releases.hashicorp.com/consul/)
* Kubernetes CLI

Tools can also be accessed using an interactive Docker shell using the command:
```
➜ ./run.sh tools
Running tools container

root@docker-desktop:/files# ls
README.md  config  consul_acl.token  dockerfiles  kubeconfig.yml  run.sh
root@docker-desktop:/files#
```

## Starting the K8s cluster with Consul Installed

```
./run.sh up
Creating K8s cluster in Docker and installing Consul
Starting test environment, this process will take approximately 2 minutes
Creating cluster "kind" ...
 ✓ Ensuring node image (kindest/node:v1.15.3) 🖼

# ...

Setup complete:

To interact with Kubernetes set your KUBECONFIG environment variable
export KUBECONFIG="$(pwd)/kubeconfig.yml

Consul can be accessed at: http://localhost:8500

When finished use ./run.sh down to cleanup and remove resources

```

Once complete you can interact with Kubernetes by setting the environment variable `KUBECONFIG`.

```
export KUBECONFIG="$(pwd)/kubeconfig.yml"

➜ kubectl get pods
NAME                                                              READY   STATUS    RESTARTS   AGE
consul-consul-connect-injector-webhook-deployment-c46d9888rq7x6   1/1     Running   0          3m38s
consul-consul-nb68d                                               1/1     Running   0          3m38s
consul-consul-server-0                                            1/1     Running   0          3m37s
```

## Interacting with the Consul
Once everything has been installed, you can access the Consul cluster at `http://localhost:8500`.

```
➜ consul members
Node                    Address          Status  Type    Build  Protocol  DC   Segment
consul-consul-server-0  10.244.0.9:8301  alive   server  1.6.1  2         dc1  <all>
kind-control-plane      10.244.0.7:8301  alive   client  1.6.1  2         dc1  <default>
```

The Consul UI can also be accessed in your browser at `http://localhost:8500/ui`

## Cleanup
To remove the Kubernetes instance and all config run the following command:

```
./run.sh down
```
