## env.sh: User specific enviroment values

# Domain name for the external ALB
export TF_VAR_alb_external_domain_name=dev.example.com

# Kubernetes cluster name
export TF_VAR_kops_cluster_name=hello.k8s.local

# Region
export AWS_DEFAULT_REGION=us-west-2

# Availability Zones
# Multiple zones are strongly recommended because RDS and ALB requires multiple zones.
export KOPS_CLUSTER_ZONES="${AWS_DEFAULT_REGION}a,${AWS_DEFAULT_REGION}b,${AWS_DEFAULT_REGION}c"

# Set kops default values
export KOPS_STATE_STORE_BUCKET_NAME="state.$TF_VAR_kops_cluster_name"
export KOPS_STATE_STORE="s3://$KOPS_STATE_STORE_BUCKET_NAME"
export KOPS_CLUSTER_NAME="$TF_VAR_kops_cluster_name"

# Use binaries in .bin
export PATH="$(cd $(dirname "$0") && pwd)/.bin:$PATH"

# Load environment values excluded from VCS
[ -f .env ] && source .env
