# Hello kubernetes with HTTPS

Hello world with kops, nginx-ingress-controller, ALB, ACM and persistent volume (EBS).

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
export KOPS_STATE_STORE=s3.$TF_VAR_kops_cluster_name
```

Create a bucket for the kops state store and the Terraform state store.

```sh
aws s3api create-bucket \
  --bucket $KOPS_STATE_STORE \
  --region $AWS_DEFAULT_REGION
aws s3api put-bucket-versioning \
  --bucket $KOPS_STATE_STORE \
  --versioning-configuration Status=Enabled
```

### Create a cluster

Generate a key pair to connect to Kubernetes nodes.

```sh
ssh-keygen -f .sshkey
```

Create a cluster.

```sh
kops create cluster \
  --name ${TF_VAR_kops_cluster_name} \
  --zones ${AWS_DEFAULT_REGION}a \
  --master-size t2.micro \
  --node-size t2.micro \
  --ssh-public-key=.sshkey.pub
  #--ssh-access=x.x.x.x/x
  #--admin-access=x.x.x.x/x
kops update cluster $KOPS_NAME --yes
kops validate cluster
kubectl get nodes
```

### Create a load balancer

Initialize Terraform.

```sh
cd ./aws
terraform init \
  -backend-config="bucket=$KOPS_STATE_STORE" \
  -backend-config="key=terraform.tfstate"
```

Create a load balancer and update the Route53 zone.

```sh
terraform plan
terraform apply
```

### Install the ingress controller

Initialize the helm.

```sh
helm init
helm repo update
```

Install the ingress controller.

```sh
helm install stable/nginx-ingress --namespace kube-system --name nginx-ingress -f helm-nginx-ingress-config.yaml
```

### Install the dashboard

Install the dashboard.

```sh
helm install stable/kubernetes-dashboard --namespace kube-system --name kubernetes-dashboard
kubectl proxy
```

Open http://localhost:8001/api/v1/namespaces/kube-system/services/kubernetes-dashboard-kubernetes-dashboard/proxy/.

### Deploy echoserver

Create a deployment, service and ingress.

```sh
kubectl apply -f hello
```

Open https://echoservice1.example.com.

### Deploy Jenkins

Create a deployment, service and persistent volume claim (EBS).
Also update the ingress.

```sh
kubectl apply -f jenkins
```

Open https://jenkins.example.com.

## Cleanup

```sh
terraform destroy
kops delete cluster --name $KOPS_NAME --yes
```
