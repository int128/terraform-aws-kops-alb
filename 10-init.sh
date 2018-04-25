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

# Initialize kubecontext
kops export kubecfg
kops validate cluster

# Initialize Terraform
pushd terraform
terraform init -backend-config="bucket=$KOPS_STATE_STORE_BUCKET_NAME"
popd

# Initialize Helm
helm init --client-only
