# Hello kubernetes with HTTPS

Hello world with kops, alb-ingress-controller, ALB and ACM.

## Setup a cluster

Configure IAM, S3 and Route53 as https://github.com/kubernetes/kops/blob/master/docs/aws.md.

Export cluster info as environment variables.

```sh
# .env
export AWS_ACCESS_KEY_ID=
export AWS_SECRET_ACCESS_KEY=
export NAME=
export KOPS_STATE_STORE=s3://
```

Create a cluster.

```sh
kops create cluster --zones us-west-2a,us-west-2b,us-west-2c --master-size t2.medium --node-size t2.micro $NAME
kops update cluster $NAME --yes
kops validate cluster
kubectl get nodes
```

## Setup an ingress

Attach [a policy](https://github.com/coreos/alb-ingress-controller/blob/master/examples/iam-policy.json) to the IAM role of nodes.

Add following tags to subnets of nodes.

- `kubernetes.io/cluster/hello`: `shared`
- `kubernetes.io/role/alb-ingress`: (empty value)

Create a default backend and an ingress controller.

```sh
kubectl apply -f https://raw.githubusercontent.com/coreos/alb-ingress-controller/master/examples/default-backend.yaml

kubectl apply -f alb-ingress-controller.yaml
kubectl -n kube-system get pods
kubectl logs -n kube-system alb-ingress-controller-***
```

Create an ingress.

```sh
kubectl apply -f hello
kubectl logs -n kube-system -f --tail=100 alb-ingress-controller-***
```

## Setup Route53 and ALB

Create an A record of wildcard domain `*.kops.hidetake.org` pointing to the ALB created.

Then, access to the endpint.

```sh
curl -v http://echo.kops.hidetake.org
```

Acquire a certificate for the wildcard domain on ACM.

Add a HTTPS lister to the ALB. Fix the associated security group to accept incoming HTTPS access.

```sh
curl -v https://echo.kops.hidetake.org
```


## Cleanup

```sh
kops delete cluster --name $NAME --yes
```
