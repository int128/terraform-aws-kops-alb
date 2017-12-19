# Hello kubernetes with HTTPS

Hello world with kops, alb-ingress-controller, ALB and ACM.

## Prerequisite

```sh
brew install kops
brew install kubernetes-helm
```

## Create a cluster

Configure IAM, S3 and Route53 as https://github.com/kubernetes/kops/blob/master/docs/aws.md.

Export cluster info as environment variables.

```sh
# .env
export AWS_ACCESS_KEY_ID=
export AWS_SECRET_ACCESS_KEY=
export KOPS_NAME=kops.example.com
export KOPS_STATE_STORE=s3://hello-kops-xxxxxxxx
```

Create a cluster.

```sh
kops create cluster \
  --name $KOPS_NAME \
  --zones us-west-2a,us-west-2b,us-west-2c \
  --master-size t2.micro \
  --node-size t2.micro
  #--ssh-access=x.x.x.x/x
  #--admin-access=x.x.x.x/x
  #--ssh-public-key=key.pub
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
helm install --name hello-kubernetes-dashboard stable/kubernetes-dashboard
kubectl proxy
```

Open http://localhost:8001/api/v1/namespaces/default/services/hello-kubernetes-dashboard-kubernetes-dashboard/proxy/.

## Create an ingress

Configure IAM and Security Group as https://github.com/coreos/alb-ingress-controller/blob/master/docs/setup.md.

- Attach [the IAM policy](https://github.com/coreos/alb-ingress-controller/blob/master/examples/iam-policy.json) to the IAM role for nodes.
- Create a security group for ALBs.
- Acquire a certificate for the wildcard domain on ACM.

Install an ingress controller and create an ingress.

```sh
helm registry install quay.io/coreos/alb-ingress-controller-helm --set awsRegion=us-west-2 --set rbac.create=false
```

Fix security groups, subnets and the certificate in `ingress.yaml`.

```sh
kubectl apply -f hello
```

## Cleanup

```sh
kops delete cluster --name $KOPS_NAME --yes
```
