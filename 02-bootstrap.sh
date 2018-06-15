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
aws --version
kops version
terraform version
helm version -c
helmfile -v

# Generate a key pair to connect to EC2 instances
if [ ! -f .sshkey ]; then
  ssh-keygen -f .sshkey -N ''
fi

# Create a S3 bucket for kops and Terraform
aws s3api create-bucket \
  --bucket "$KOPS_STATE_STORE_BUCKET_NAME" \
  --region "$AWS_DEFAULT_REGION" \
  --create-bucket-configuration "LocationConstraint=$AWS_DEFAULT_REGION"

aws s3api put-bucket-versioning \
  --bucket "$KOPS_STATE_STORE_BUCKET_NAME" \
  --versioning-configuration "Status=Enabled"

# Create a cluster configuration
kops create cluster \
  --name "$KOPS_CLUSTER_NAME" \
  --zones "$KOPS_CLUSTER_ZONES" \
  --authorization RBAC \
  --ssh-public-key .sshkey.pub \
  --node-count 1 \
  --node-size m4.large \
  --master-size t2.medium

# Create AWS resources
kops update cluster --name "$KOPS_CLUSTER_NAME"
kops update cluster --name "$KOPS_CLUSTER_NAME" --yes

# Make sure you can access to the cluster
kops validate cluster --name "$KOPS_CLUSTER_NAME"

# Initialize Terraform
terraform init -backend-config="bucket=$KOPS_STATE_STORE_BUCKET_NAME"

# Create AWS resources
terraform apply

# Initialize Helm
kubectl create -f helm-service-account.yaml
helm init --service-account tiller
helm version

# Install Helm charts
helmfile sync
