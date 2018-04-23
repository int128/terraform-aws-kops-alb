export TF_VAR_kops_cluster_name=hello.k8s.local
export TF_VAR_alb_external_domain_name=dev.example.com
export AWS_DEFAULT_REGION=us-west-2
export KOPS_STATE_STORE_BUCKET=state.$TF_VAR_kops_cluster_name
export KOPS_STATE_STORE=s3://$KOPS_STATE_STORE_BUCKET
[ -f .env ] && source .env
