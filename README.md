# Kubernetes starter on AWS with kops and Terraform

This is a Kubernetes starter on AWS with kops and Terraform to build the following stack.

![k8s-alb-kops-terraform.png](k8s-alb-kops-terraform.png)

## Goals

- You can operate the Kunernetes cluster by `kubectl`.
- You can access to services on the cluster through HTTPS.

This tutorial introduces the followings:

- Kubernetes
- nginx-ingress-controller
- Kubernetes dashboard
- Heapster

## Getting Started

### Prerequisite

You must have the followings:

- a domain or subdomain
- an AWS account
- an IAM user with [these permissions](https://github.com/kubernetes/kops/blob/master/docs/aws.md)
- a Route53 hosted zone for the domain, e.g. `dev.example.com`
- an ACM certificate for the wildcard name, e.g. `*.dev.example.com`

Install following tools:

```sh
brew install kops
brew install kubernetes-helm
brew install awscli
brew install terraform
```

### 1. Create a state store

Set the cluster information.

```sh
# .env
export TF_VAR_kops_cluster_name=hello.k8s.local
export TF_VAR_alb_external_domain_name=dev.example.com
export AWS_DEFAULT_REGION=us-west-2
export KOPS_STATE_STORE=s3://state.$TF_VAR_kops_cluster_name
```

Create a bucket for the kops state store and the Terraform state store.

```sh
aws s3api create-bucket \
  --bucket state.$TF_VAR_kops_cluster_name \
  --region $AWS_DEFAULT_REGION \
  --create-bucket-configuration LocationConstraint=$AWS_DEFAULT_REGION
aws s3api put-bucket-versioning \
  --bucket state.$TF_VAR_kops_cluster_name \
  --versioning-configuration Status=Enabled
```

### 2. Create a Kubernetes cluster

Generate a key pair to connect to Kubernetes nodes.

```sh
ssh-keygen -f .sshkey
```

Create a cluster.

```sh
kops create cluster \
  --name ${TF_VAR_kops_cluster_name} \
  --zones ${AWS_DEFAULT_REGION}a,${AWS_DEFAULT_REGION}b,${AWS_DEFAULT_REGION}c \
  --authorization RBAC \
  --ssh-public-key=.sshkey.pub
kops update cluster $TF_VAR_kops_cluster_name
kops update cluster $TF_VAR_kops_cluster_name --yes
kops validate cluster
kubectl get nodes
```

### 3. Create a load balancer and ingress controller

Initialize Terraform.

```sh
cd ./terraform
terraform init \
  -backend-config="bucket=state.$TF_VAR_kops_cluster_name" \
  -backend-config="key=terraform.tfstate"
```

Create a load balancer and update the Route53 hosted zone.

```sh
terraform plan
terraform apply
```

Initialize Helm.

```sh
kubectl create -f config/helm-rbac-config.yaml
helm init --service-account tiller
helm repo update
```

Install an ingress controller.

```sh
helm install stable/nginx-ingress --namespace system --name nginx-ingress -f config/helm-nginx-ingress.yaml
```

Open https://dummy.dev.example.com and it should show `default backend - 404`.

### 4. Test an ingress with echoserver

Create a deployment, service and ingress.

```sh
kubectl apply -f config/echoserver.yaml
```

Open https://echoserver.dev.example.com.

### 5. Install Kubernetes Dashboard

Install Heapster.

```sh
helm install stable/heapster --namespace kube-system --name heapster -f config/helm-heapster.yaml
```

Install Kubernetes Dashboard.

```sh
helm install stable/kubernetes-dashboard --namespace kube-system --name kubernetes-dashboard -f config/helm-kubernetes-dashboard.yaml
kubectl proxy
```

Open http://localhost:8001/api/v1/namespaces/kube-system/services/kubernetes-dashboard/proxy/.

### Cleanup

```sh
terraform destroy
kops delete cluster --name $TF_VAR_kops_cluster_name --yes
```

WARNING: `kops delete cluster` command will delete all EBS volumes tagged.
You should take a snapshot before doing that.

## Tips

### Working with managed services

You can attach the security group `allow-from-nodes.hello.k8s.local` to managed services such as RDS.

### Team development

It is recommended that the cluster name, S3 bucket name and AWS region are described in [`terraform/vars.tf`](terraform/vars.tf) for team development.
You can guide a team member as follows:

Install following tools:

```sh
brew install kops
brew install kubernetes-helm
brew install terraform
```

Initialize the kubectl context.

```sh
kops export kubecfg --state=s3://state.hello.k8s.local --name hello.k8s.local
kubectl get nodes
```

Initialize the Terraform.

```sh
cd terraform
terraform init
```

### Restrict access

You can restrict API and SSH access by editing the cluster spec.

```sh
kops edit cluster
```

```yaml
spec:
  kubernetesApiAccess:
  - xxx.xxx.xxx.xxx/32
  sshAccess:
  - xxx.xxx.xxx.xxx/32
```

You can restrict access to services (the external ALB) by Terraform.
Also you should enable the internal ALB to make nodes can access to services via the same domain.

```yaml
variable "alb_external_allow_ip" {
  default = [
    "xxx.xxx.xxx.xxx/32",
  ]
}

variable "alb_internal_enabled" {
  default = false
}
```

### Reduce cost for testing purpose

Since a gossip-based cluster needs an ELB for masters and it costs $18/month at least,
create a DNS based cluster instead.

```sh
# .env
export TF_VAR_kops_cluster_name=dev.example.com
```

Master:

```sh
kops edit ig master-us-west-2a --name $TF_VAR_kops_cluster_name
```

```yaml
spec:
  machineType: t2.micro
  rootVolumeSize: 20
  rootVolumeType: standard
```

Nodes:

```sh
kops edit ig nodes --name $TF_VAR_kops_cluster_name
```

```yaml
spec:
  machineType: m3.medium
  maxPrice: "0.02"
  rootVolumeSize: 20
  rootVolumeType: standard
  subnets:
  - us-west-2a
```
