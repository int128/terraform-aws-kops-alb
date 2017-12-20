# Hello kubernetes with HTTPS

Hello world with kops, nginx-ingress-controller, ALB, ACM and persistent volume (EBS).

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

## Install the ingress controller

Install the ingress controller.

```sh
helm install stable/nginx-ingress \
  --set controller.service.type=NodePort \
  --set controller.service.nodePorts.http=30080
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
