# Hello kubernetes with HTTPS

Hello world with kops, nginx-ingress-controller, ALB, ACM and persistent volume (EBS).

## Prerequisite

```sh
brew install kops
brew install kubernetes-helm
brew install awscli
```

You must have followings:

- an AWS account.
- an IAM user that has [these permissions](https://github.com/kubernetes/kops/blob/master/docs/aws.md)
- a Route53 hosted zone (see [DNS configuration](https://github.com/kubernetes/kops/blob/master/docs/aws.md))

## Create a cluster

Export cluster info as environment variables.

```sh
export AWS_ACCESS_KEY_ID="$(aws configure get aws_access_key_id)"
export AWS_SECRET_ACCESS_KEY="$(aws configure get aws_secret_access_key)"
export KOPS_NAME=kops.example.com
export KOPS_STATE_STORE=s3://kops-state-$KOPS_NAME
export KOPS_REGION=us-west-2
```

Create a S3 bucket.

```sh
aws s3api create-bucket --bucket $KOPS_STATE_STORE --region $KOPS_REGION
aws s3api put-bucket-versioning --bucket $KOPS_STATE_STORE --versioning-configuration Status=Enabled
```

Generate a key pair to connect to Kubernetes nodes.

```sh
ssh-keygen -f .sshkey
```

Create a cluster.

```sh
kops create cluster \
  --name $KOPS_NAME \
  --zones ${KOPS_REGION}a \
  --master-size t2.micro \
  --node-size t2.micro \
  --ssh-public-key=.sshkey.pub
  #--ssh-access=x.x.x.x/x
  #--admin-access=x.x.x.x/x
kops update cluster $KOPS_NAME --yes
kops validate cluster
kubectl get nodes
```

Initialize the helm.

```sh
helm init
helm repo update
```

## Install the dashboard

Install the dashboard.

```sh
helm install stable/kubernetes-dashboard --namespace kube-system --name kubernetes-dashboard
kubectl proxy
```

Open http://localhost:8001/api/v1/namespaces/kube-system/services/kubernetes-dashboard-kubernetes-dashboard/proxy/.

## Install the ingress controller

Install the ingress controller.

```sh
helm install stable/nginx-ingress --namespace kube-system --name nginx-ingress -f helm-nginx-ingress-config.yaml
```

Create AWS objects.

- Create a security group for the ALB.
- Permit access from the ALB to nodes. 
- Issue a certificate for the wildcard domain on ACM.
- Create an ALB and route to port 30080 of nodes.
- Attach the auto scaling group of nodes to the target group.

## Deploy echoserver

Create a deployment, service and ingress.

```sh
kubectl apply -f hello
```

Open https://echoservice1.example.com.

## Deploy Jenkins

Create a deployment, service and persistent volume claim (EBS).
Also update the ingress.

```sh
kubectl apply -f jenkins
```

Open https://jenkins.example.com.

## Cleanup

```sh
kops delete cluster --name $KOPS_NAME --yes
```
