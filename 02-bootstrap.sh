#!/bin/bash
#
# Bootstrap the Kubernetes cluster and AWS resources.
# See README.
#
if [ -z "$KOPS_CLUSTER_NAME" ]; then
  echo "Run the following command before running $0"
  echo '  source 01-env.sh'
  exit 1
fi

set -e
set -o pipefail
set -x
cd "$(dirname "$0")"

# Show versions
kops version
terraform version
helm version -c
helmfile -v

# Make sure you can access to the cluster
while ! kops validate cluster; do
  echo "Waiting until the cluster is available..."
  sleep 10
done

# Create AWS resources
terraform apply

# Initialize Helm
kubectl create -f helm-service-account.yaml
helm init --service-account tiller --history-max 100
while ! helm version; do
  echo "Waiting until the helm tiller is available..."
  sleep 10
done

# Install Helm charts
helmfile sync

# Switch default storage class to EFS
kubectl patch storageclass gp2 -p '{"metadata": {"annotations": {"storageclass.beta.kubernetes.io/is-default-class": null}}}'
