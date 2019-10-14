#!/bin/bash
export KUBECONFIG="$(kind get kubeconfig-path --name="kind")"

function up() {
	kind create cluster --config ./config.yml

  # Export KubeConfig
  cat $(kind get kubeconfig-path) --name="kind" > ./kubeconfig.yaml
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
  until kubectl get pods -l component=server --field-selector=status.phase=Running | grep "/1" | grep -v "0/"; do
    echo "Waiting for Consul server to start"
    sleep 1
  done
  
  # Wait for Consul client to be ready
  until kubectl get pods -l component=client --field-selector=status.phase=Running | grep "/1" | grep -v "0/"; do
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
  kind delete cluster
}

case "$1" in
  "up")
    echo "Starting test environment, this process will take approximately 2 minutes";
    sleep 5
    up;
    echo "Installing and configuring environment";
    install_core;
    install_consul;
    install_smi;

    echo "";
    echo "Setup complete:";
    echo "";
    echo "To interact with Kubernetes set your KUBECONFIG environment variable";
    echo "export KUBECONFIG=\"$(kind get kubeconfig-path --name=\"kind\")";
    echo ""
    echo "Consul can be accessed at: http://localhost:8500"
    echo ""
    echo "When finished use ./run.sh down to cleanup and remove resources";
    ;;
  "down")
    echo "Stopping Kubernetes and cleaning resources"
    down;
    ;;
  *)
    echo "Options"
    echo "  up           - Start K8s server"
    echo "  down         - Stop K8s server"
    exit 1 
    ;;
esac
