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

# Generate a key pair to connect to EC2 instances
if [ ! -f .sshkey ]; then
  ssh-keygen -f .sshkey -N ''
fi

# Create a cluster configuration
kops create cluster \
  --name "$KOPS_CLUSTER_NAME" \
  --zones "${AWS_DEFAULT_REGION}a,${AWS_DEFAULT_REGION}c" \
  --authorization RBAC \
  --ssh-public-key .sshkey.pub \
  --node-count 1 \
  --master-size t2.medium

# Make single AZ nodes
kops create instancegroup "nodes-${AWS_DEFAULT_REGION}a" --name "$KOPS_CLUSTER_NAME" --subnet "${AWS_DEFAULT_REGION}a" --edit=false
kops delete instancegroup nodes --name "$KOPS_CLUSTER_NAME" --yes

# Create AWS resources
kops update cluster --name "$KOPS_CLUSTER_NAME" --yes

# Make sure you can access to the cluster
while ! kops validate cluster --name "$KOPS_CLUSTER_NAME"; do
  echo "Waiting until the cluster is available..."
  sleep 30
done

# Initialize Terraform
terraform init -backend-config="bucket=$TF_VAR_state_store_bucket_name"

# Create AWS resources
terraform apply

# Initialize Helm
kubectl create -f helm-service-account.yaml
helm init --service-account tiller
helm version

# Install Helm charts
helmfile sync
