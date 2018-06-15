# Kubernetes on AWS with kops and Terraform

This bootstraps the following stack in a few minutes:

![aws-diagram.png](images/aws-diagram.png)

## Goals

- Publish your services via [nginx-ingress](https://github.com/kubernetes/charts/tree/master/stable/nginx-ingress), ALB, ACM and Route53.
- Manage your Kubernetes cluster by `kubectl` and `kops`.
- Manage your AWS resources by `terraform`.
- Manage your Helm releases by `helmfile`.


## Build a new cluster

Make sure you have the following items:

- An AWS account
- An IAM user with [these permissions](https://github.com/kubernetes/kops/blob/master/docs/aws.md)
- A domain or subdomain, e.g. `dev.example.com`

Install the following tools:

```sh
# macOS
brew install awscli kubectl kops helm terraform
./00-install.sh   # Install helmfile

# WSL/Ubuntu
sudo apt install awscli
./00-install.sh   # Install kubectl, kops, helm, terraform and helmfile
```


### 1. Configure

Configure your AWS credentials.

```sh
aws configure --profile example
```

Change [`01-env.sh`](01-env.sh) with your environment values.
If you do not want to push the environment values to the Git repository, you can put your values into `.env` instead.


### 2. Setup DNS, Certificate and S3

**Route53:** Create a public hosted zone for the domain, e.g. `dev.example.com`.
You may need to add the NS record to the parent zone.

**ACM:** Request a certificate for the wildcard domain, e.g. `*.dev.example.com`.
The certificate will be attached to an ALB later.

**S3:** Create a bucket for state store of kops and Terraform.
You must enable bucket versioning.
You can do it from AWS CLI by the following:

```sh
source 01-env.sh
aws s3api create-bucket \
  --bucket "$state_store_bucket_name" \
  --region "$AWS_DEFAULT_REGION" \
  --create-bucket-configuration "LocationConstraint=$AWS_DEFAULT_REGION"
aws s3api put-bucket-versioning \
  --bucket "$state_store_bucket_name" \
  --versioning-configuration "Status=Enabled"
```


### 3. Bootstrap

In this section, we will create the following components:

- kops
  - A Kubernetes master in a single AZ
  - A Kubernetes node in a single AZ
- Terraform
  - An internet-facing ALB
  - A Route53 record for the internet-facing ALB
  - A security group for the internet-facing ALB
- kubectl
  - `ServiceAccount` and `ClusterRoleBinding` for the Helm tiller
  - `echoserver`
- Helm
  - `nginx-ingress`

Run the following commands to bootstrap a cluster.

```sh
source 01-env.sh
./02-bootstrap.sh
```


### 4. Customize

```sh
source 01-env.sh

# Now you can execute the following tools.
kops
terraform
helmfile
```

#### 4-1. Single AZ nodes

You can change the nodes running in a single AZ by changing the instance group:

```sh
kops edit ig nodes
```

```yaml
spec:
  subnets:
  - us-west-2a
```

Apply the change:

```sh
kops update cluster
kops update cluster --yes
```


#### 4-2. Restrict access

You can restrict the following accesses to specific IP addresses.

- Kubernetes API
- SSH
- internet-facing ALB

To change access control for the Kubernetes API and SSH:

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

Apply the changes for the Kubernetes API and SSH:

```sh
kops update cluster
kops update cluster --yes
```

To change access control for the internet-facing ALB, edit `vars.tf`:

```tf
variable "alb_external_allow_ip" {
  default = [
    "xxx.xxx.xxx.xxx/32",
    "xxx.xxx.xxx.xxx/32",
  ]
}

variable "alb_internal_enabled" {
  default = true
}
```

Apply the changes for the internet-facing ALB:

```sh
terraform apply
```

The following resources are created so that the masters and nodes can access to services in the VPC.

- An internal ALB
- A Route53 private hosted zone for the internal ALB
- A Route53 record for the internal ALB
- A security group for the internal ALB


#### 4-3. Working with managed services

Terraform creates the security group `allow-from-nodes.hello.k8s.local` which allows access from the Kubernetes nodes.
You can attach the security group to managed services such as RDS or Elasticsearch.


## Manage the cluster

Tell the following steps to your team members.

### On boarding

```sh
source 01-env.sh
./10-init.sh
```

### Daily operation

```sh
source 01-env.sh

# Now you can execute the following tools.
kops
terraform
helmfile
```


## Destroy the cluster

**WARNING:** `kops delete cluster` command will delete all EBS volumes with a tag.
You should take snapshots before destroying.

```sh
terraform destroy
kops delete cluster --name "$KOPS_CLUSTER_NAME" --yes
```


## Cost

Running cost depends on number of masters and nodes.

### Minimize cost for testing

Here is a minimum configuration with AWS Free Tier (first 1 year):

Role | Kind | Spec | Monthly Cost
-----|------|------|-------------
Master  | EC2 | m3.medium spot | $5
Master  | EBS | gp2 10GB | free
Master  | EBS for etcd | gp2 5GB x2 | free
Node    | EC2 | m3.medium spot | $5
Node    | EBS | gp2 10GB | free
Cluster | EBS for PVs | gp2 | $0.1/GB
Cluster | ALB | - | free
Cluster | Route53 Hosted Zone | - | $0.5
Cluster | S3  | - | free
Managed | RDS | t2.micro gp2 20GB | free
Managed | Elasticsearch | t2.micro gp2 10GB | free

The cluster name must be a domain name in order to reduce an ELB for masters.

```sh
# 01-env.sh
kubernetes_cluster_name=dev.example.com
```

Reduce size of the volumes:

```yaml
# kops edit cluster
spec:
  etcdClusters:
  - etcdMembers:
    - instanceGroup: master-us-west-2a
      name: a
      volumeSize: 5
    name: main
    version: 3.2.14
  - etcdMembers:
    - instanceGroup: master-us-west-2a
      name: a
      volumeSize: 5
    name: events
    version: 3.2.14
---
# kops edit ig master-us-west-2a
spec:
  machineType: m3.medium
  maxPrice: "0.02"
  rootVolumeSize: 10
---
# kops edit ig nodes
spec:
  machineType: m3.medium
  maxPrice: "0.02"
  rootVolumeSize: 10
  subnets:
  - us-west-2a
```


## Contribution

This is an open source software licensed under Apache License 2.0.
Feel free to bring up issues or pull requests.
