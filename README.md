# Kubernetes on AWS with kops and Terraform

This bootstraps the following stack in a few minutes:

![aws-diagram.png](aws-diagram.png)

## Goals

- Publish your services via [nginx-ingress](https://github.com/kubernetes/charts/tree/master/stable/nginx-ingress), ALB, ACM and Route53.
- Manage your Kubernetes cluster by `kubectl` and `kops`.
- Manage your AWS resources by `terraform`.
- Manage your Helm releases by `helmfile`.

## Getting Started

### Prerequisite

Make sure you have the following items:

- an AWS account
- an IAM user with [these permissions](https://github.com/kubernetes/kops/blob/master/docs/aws.md)
- a domain or subdomain
- a Route53 public hosted zone for the domain, e.g. `dev.example.com`
- a certificate with the wildcard domain in ACM, e.g. `*.dev.example.com`

Install the following tools:

```sh
# macOS
brew install awscli kubectl kops helm terraform
./00-install.sh   # This will install helmfile

# Windows Subsystem for Linux (WSL)
sudo apt install awscli
./00-install.sh   # This will install kubectl, kops, helm, terraform and helmfile
```


### 1. Configure

Change [`01-env.sh`](01-env.sh) with your environment values.
If you do not want to push the environment values to the Git repository, you can put your values into `.env` instead.


### 2. Bootstrap

In this section, we will create the following components:

- using kops
  - A Kubernetes master in a single AZ
  - A Kubernetes node in a single AZ
- using Terraform
  - An internet-facing ALB
  - A Route53 record for the internet-facing ALB
  - A security group for the internet-facing ALB
- using kubectl
  - `ServiceAccount` and `ClusterRoleBinding` for the Helm tiller
  - `echoserver`
- using Helm
  - `nginx-ingress`

Run the following commands to bootstrap a cluster.

```sh
./02-bootstrap.sh
```


### 3. Customize

Load the environment values.

```sh
source 01-env.sh
```

After that you can use `kops` and `terraform`.


#### Recipe: Single AZ nodes

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


#### Recipe: Restrict IP addresses

You can restrict API access and SSH access for specific IP addresses by changing the cluster spec:

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

Apply the changes:

```sh
kops update cluster
kops update cluster --yes

kops rolling-update cluster
kops rolling-update cluster --yes
```

You can restrict access to the internet-facing ALB by changing the following in `vars.tf`.

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

Apply the changes:

```sh
cd terraform
terraform apply
```

The additional resources will be created in order to allow the masters and nodes have access to services.

- An internal ALB
- A Route53 private hosted zone for the internal ALB
- A Route53 record for the internal ALB
- A security group for the internal ALB


#### Recipe: Working with managed services

Terraform creates the security group `allow-from-nodes.hello.k8s.local` which allows access from the Kubernetes nodes.
You can attach the security group to managed services such as RDS or Elasticsearch.


### 4. Team operation

Tell the following steps to your team members.

#### On boarding

```sh
./10-init.sh
```

#### Daily operation

```sh
source 01-env.sh

# Now you can execute the following tools.
kops
terraform
helmfile
```

### 5. Destroy

**WARNING:** `kops delete cluster` command will delete all EBS volumes with a tag.
You should take snapshots before destroying.

```sh
terraform destroy
kops delete cluster --name $TF_VAR_kops_cluster_name --yes
```


## Cost

Running cost depends on number of masters and nodes.

Here is a minimum cost configuration with AWS Free Tier (first 1 year):

Role | Kind | Spec | Monthly Cost
-----|------|------|-------------
Master  | EC2 | m3.medium spot | $5
Master  | EBS | standard 10GB | $0.5
Master  | EBS for etcd | standard 10GB x2 | $1
Node    | EC2 | m3.medium spot | $5
Node    | EBS | standard 20GB | $1
Cluster | EBS for PVs | gp2 30GB | free
Cluster | ALB | -              | free
Cluster | Route53 Hosted Zone | - | $0.5
Managed | RDS | t2.micro gp2 20GB | free
Managed | Elasticsearch | t2.micro gp2 10GB | free

If 1 master and 2 nodes are running, they cost $14 per a month.

The cluster name must be a domain name in order to reduce an ELB for masters.

```sh
export TF_VAR_kops_cluster_name=dev.example.com
```

Then change the volume type to `standard` and reduce size:

```yaml
# kops edit cluster --name $TF_VAR_kops_cluster_name
spec:
  etcdClusters:
  - etcdMembers:
    - instanceGroup: master-us-west-2a
      name: a
      volumeSize: 10
      volumeType: standard
    name: main
    version: 3.2.14
  - etcdMembers:
    - instanceGroup: master-us-west-2a
      name: a
      volumeSize: 10
      volumeType: standard
    name: events
    version: 3.2.14
---
# kops edit ig master-us-west-2a --name $TF_VAR_kops_cluster_name
spec:
  machineType: t2.micro
  rootVolumeSize: 10
  rootVolumeType: standard
---
# kops edit ig nodes --name $TF_VAR_kops_cluster_name
spec:
  machineType: m3.medium
  maxPrice: "0.02"
  rootVolumeSize: 20
  rootVolumeType: standard
  subnets:
  - us-west-2a
```

## Contribution

This is an open source software licensed under Apache License 2.0.
Feel free to bring up issues or pull requests.
