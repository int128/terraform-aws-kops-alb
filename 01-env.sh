## Environment specific values.

# Domain name for the external ALB.
kubernetes_ingress_domain=dev.example.com

# Kubernetes cluster name.
kubernetes_cluster_name=hello.j8s.local

# AWS Profile.
export AWS_PROFILE=example

# AWS Region.
export AWS_DEFAULT_REGION=us-west-2

# AWS Availability Zones.
# Note: RDS and ALB requires multiple zones.
export KOPS_CLUSTER_ZONES="${AWS_DEFAULT_REGION}a,${AWS_DEFAULT_REGION}c"



## Environment variables for tools.

# kops
export KOPS_STATE_STORE_BUCKET_NAME="state.$kubernetes_cluster_name"
export KOPS_STATE_STORE="s3://$KOPS_STATE_STORE_BUCKET_NAME"
export KOPS_CLUSTER_NAME="$kubernetes_cluster_name"

# Terraform
export TF_VAR_alb_external_domain_name="$kubernetes_ingress_domain"
export TF_VAR_kops_cluster_name="$kubernetes_cluster_name"

# Use binaries in .bin
export PATH="$(cd $(dirname -- "$0") && pwd)/.bin:$PATH"



# Load environment values excluded from VCS
if [ -f .env ]; then
  source .env
fi
