#!/bin/bash
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
  ssh-keygen -f .sshkey
fi

# Create a S3 bucket for kops and Terraform
aws s3api create-bucket \
  --bucket "$KOPS_STATE_STORE_BUCKET" \
  --region "$AWS_DEFAULT_REGION" \
  --create-bucket-configuration "LocationConstraint=$AWS_DEFAULT_REGION"

aws s3api put-bucket-versioning \
  --bucket "$KOPS_STATE_STORE_BUCKET" \
  --versioning-configuration "Status=Enabled"

# Create a cluster configuration
kops create cluster \
  --name "$TF_VAR_kops_cluster_name" \
  --zones "$KOPS_CLUSTER_ZONES" \
  --authorization RBAC \
  --ssh-public-key .sshkey.pub \
  --node-count 1 \
  --node-size t2.medium \
  --master-size t2.medium

# Create AWS resources
kops update cluster $TF_VAR_kops_cluster_name
kops update cluster $TF_VAR_kops_cluster_name --yes

# Make sure you can access to the cluster
kops validate cluster

# Initialize Terraform
pushd terraform
terraform init \
  -backend-config="bucket=$KOPS_STATE_STORE_BUCKET" \
  -backend-config="key=terraform.tfstate"

# Create AWS resources
terraform apply
popd

# Initialize Helm
kubectl create -f config/helm-rbac.yaml
helm init --service-account tiller
helm version

# Install Helm charts
helmfile sync

# Test the ingress controller
sed -e "s/TF_VAR_alb_external_domain_name/$TF_VAR_alb_external_domain_name" config/echoserver.yaml | kubectl apply -f -
curl -v --retry 10 --retry-connrefused "https://echoserver.$TF_VAR_alb_external_domain_name"
