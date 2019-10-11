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

* kubectl (https://kubernetes.io/docs/tasks/tools/install-kubectl/)
* helm (https://helm.sh/docs/using_helm/#install-helm)
* docker (https://docs.docker.com/install/)
* kind (https://kind.sigs.k8s.io/)

## Starting the K8s cluster with Consul Installed

```
./run.sh up
```

Once complete you can interact with Kubernetes by setting the environment variable `KUBECONFIG`.

```
export KUBECONFIG="/Users/nicj/.kube/kind-config-"kind"

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
