# Hello kops

Configure IAM, S3 and Route53 as https://github.com/kubernetes/kops/blob/master/docs/aws.md.

```sh
# .env
export AWS_ACCESS_KEY_ID=
export AWS_SECRET_ACCESS_KEY=
export NAME=
export KOPS_STATE_STORE=s3://
```

Create a cluster.

```sh
kops create cluster --zones us-west-2a --master-size t2.medium --node-size t2.micro $NAME
kops update cluster $NAME --yes
kops validate cluster
kubectl get nodes
```

Cleanup.

```sh
kops delete cluster --name $NAME --yes
```
