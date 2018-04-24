## env.sh: User specific enviroment values

# Domain name for the external ALB
export TF_VAR_alb_external_domain_name=dev.example.com

# Kubernetes cluster name
export TF_VAR_kops_cluster_name=hello.k8s.local

# Region
export AWS_DEFAULT_REGION=us-west-2

# S3 bucket name for kops and Terraform state store
export KOPS_STATE_STORE_BUCKET=state.$TF_VAR_kops_cluster_name
export KOPS_STATE_STORE=s3://$KOPS_STATE_STORE_BUCKET

# Use binaries in .bin
export PATH="$(cd $(dirname "$0") && pwd)/.bin:$PATH"

# Load environment values excluded from VCS
[ -f .env ] && source .env
