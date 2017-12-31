# Kubernetes starter with kops and Terraform

This is a Kubernetes starter with kops and Terraform to build the following stack.

![k8s-alb-kops-terraform.png](k8s-alb-kops-terraform.png)

## Goals

- You can operate the cluster by `kops`
- You can access to the Kunernetes API by `kubectl`
- You can access to services via a HTTPS wildcard domain

## Getting Started

### Prerequisite

You must have followings:

- an AWS account
- an IAM user with [these permissions](https://github.com/kubernetes/kops/blob/master/docs/aws.md)
- [a Route53 hosted zone](https://github.com/kubernetes/kops/blob/master/docs/aws.md), e.g. `kops.example.com`
- an ACM certificate for the wildcard domain of the hosted zone, e.g. `*.kops.example.com`

Install following tools:

```sh
brew install kops
brew install kubernetes-helm
brew install awscli
brew install terraform
```

### Create a state store

Set the cluster information.

```sh
# .env
export TF_VAR_kops_cluster_name=kops.example.com
export AWS_DEFAULT_REGION=us-west-2
```

Create a bucket for the kops state store and the Terraform state store.

```sh
aws s3api create-bucket \
  --bucket s3.$TF_VAR_kops_cluster_name \
  --region $AWS_DEFAULT_REGION \
  --create-bucket-configuration LocationConstraint=$AWS_DEFAULT_REGION
aws s3api put-bucket-versioning \
  --bucket s3.$TF_VAR_kops_cluster_name \
  --versioning-configuration Status=Enabled
```

### Create a cluster

Generate a key pair to connect to Kubernetes nodes.

```sh
ssh-keygen -f .sshkey
```

Create a cluster.

```sh
export KOPS_STATE_STORE=s3://s3.$TF_VAR_kops_cluster_name
kops create cluster \
  --name ${TF_VAR_kops_cluster_name} \
  --zones ${AWS_DEFAULT_REGION}a \
  --authorization RBAC \
  --ssh-public-key=.sshkey.pub
  #--ssh-access=x.x.x.x/x \
  #--admin-access=x.x.x.x/x \
  #--master-size t2.micro \
  #--master-volume-size 20 \
  #--node-size t2.micro \
  #--node-volume-size 20 \
kops update cluster $TF_VAR_kops_cluster_name --yes
kops validate cluster
kubectl get nodes
```

### Create a load balancer

Initialize Terraform.

```sh
cd ./aws
terraform init \
  -backend-config="bucket=s3.$TF_VAR_kops_cluster_name" \
  -backend-config="key=$TF_VAR_kops_cluster_name.tfstate"
```

Create a load balancer and update the Route53 zone.

```sh
terraform plan
terraform apply
```

### Install system services

Initialize the helm.

```sh
kubectl create -f helm/rbac-config.yaml
helm init --service-account tiller
helm repo update
```

Install the ingress controller.

```sh
helm install stable/nginx-ingress --namespace kube-system --name nginx-ingress -f helm/nginx-ingress-config.yaml
```

Open https://dummy.kops.example.com and it should show `default backend - 404`.

Install the dashboard.

```sh
helm install stable/kubernetes-dashboard --namespace kube-system --name kubernetes-dashboard -f helm/kubernetes-dashboard-config.yaml
kubectl proxy
```

Open http://localhost:8001/api/v1/namespaces/kube-system/services/kubernetes-dashboard-kubernetes-dashboard/proxy/.

### Deploy echoserver

Create a deployment, service and ingress.

```sh
kubectl apply -f echoserver.yaml
```

Open https://echoserver.kops.example.com.

## Cleanup

```sh
terraform destroy
kops delete cluster --name $TF_VAR_kops_cluster_name --yes
```
