#!/bin/bash
#
# Bootstrap the Kubernetes cluster and AWS resources.
# See README.
#
set -e
set -o pipefail
set -x
cd "$(dirname "$0")"

# Load the environment values
source ./01-env.sh

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
  --bucket "$KOPS_STATE_STORE_BUCKET_NAME" \
  --region "$AWS_DEFAULT_REGION" \
  --create-bucket-configuration "LocationConstraint=$AWS_DEFAULT_REGION"

aws s3api put-bucket-versioning \
  --bucket "$KOPS_STATE_STORE_BUCKET_NAME" \
  --versioning-configuration "Status=Enabled"

# Create a cluster configuration
kops create cluster \
  --zones "$KOPS_CLUSTER_ZONES" \
  --authorization RBAC \
  --ssh-public-key .sshkey.pub \
  --node-count 1 \
  --node-size t2.medium \
  --master-size t2.medium

# Create AWS resources
kops update cluster
kops update cluster --yes

# Make sure you can access to the cluster
kops validate cluster

# Initialize Terraform
pushd terraform
terraform init -backend-config="bucket=$KOPS_STATE_STORE_BUCKET_NAME"

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
sed -e "s/TF_VAR_alb_external_domain_name/$TF_VAR_alb_external_domain_name/" config/echoserver.yaml | kubectl apply -f -
curl -v --retry 10 --retry-connrefused "https://echoserver.$TF_VAR_alb_external_domain_name"
