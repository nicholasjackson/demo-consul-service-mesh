#!/bin/bash
export KUBECONFIG="$(pwd)/kubeconfig.yaml"

function up() {
	docker-compose up -d
}

function install_core() {
	# Wait for cluster to be available
	until $(kubectl get pods); do
		echo "Waiting for Kubernetes to start"
		sleep 1
	done

	# Add storage
	kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml
	kubectl get storageclass

	# Create tiller service account
	kubectl -n kube-system create serviceaccount tiller

	# Create cluster role binding for tiller
	kubectl create clusterrolebinding tiller --clusterrole cluster-admin --serviceaccount=kube-system:tiller

	# Initialize tiller and wait for complete
	helm init --wait --service-account tiller
}

function install_consul() {
  echo "Installing Consul"

	# Install the Consul helm chart	
	helm install -n consul ./helm-charts/consul-helm-0.9.0

  # Wait for Consul server to be ready
  until kubectl get pods -l component=server --field-selector=status.phase=Running | grep -v "0/"; do
    echo "Waiting for Consul server to start"
    sleep 1
  done
  
  # Wait for Consul client to be ready
  until kubectl get pods -l component=client --field-selector=status.phase=Running | grep -v "0/"; do
    echo "Waiting for Consul client to start"
    sleep 1
  done

  # Get a root ACL token and write to disk
   kubectl get secret consul-consul-bootstrap-acl-token -o json | jq -r .data.token > consul_acl.token 
}

function install_smi() {
  echo "Install SMI"

  # Install the CRDs for the controller
  kubectl apply -f ./k8s_config
}

function down() {
	docker-compose down
}

function clean() {
  echo "Removing containers and cleaning config volumes"
  docker-compose down -v
}


function proxy_consul() {
  kubectl port-forward svc/consul-consul-server 8500
}

case "$1" in
  "up")
    echo "Starting test environment"
    up;
    ;;
  "down")
    echo "Stopping Kubernetes"
    down;
    ;;
  "clean")
    echo "Stopping Kubernetes and removing all data"
    clean;
    ;;
  "install")
    echo "Installing and configuring environment"
    install_core;
    install_consul;
    install_smi;
    ;;
  "proxy_consul")
    echo "Proxying Consul server in K8s to localhost:8500"
    proxy_consul
    ;;
  *)
    echo "Options"
    echo "  up           - Start K8s server"
    echo "  down         - Stop K8s server"
    echo "  clean        - Stop K8s server and cleanup"
    echo "  install      - Install components such as Consul"
    echo "  proxy_consul - Expose Consul server on localhost:8500"
    exit 1 
    ;;
esac
