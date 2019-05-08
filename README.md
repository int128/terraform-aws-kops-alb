# Kubernetes on AWS with kops and Terraform

This bootstraps the following stack in a few minutes:

![aws-diagram.png](images/aws-diagram.png)

## Goals

- Expose services via HTTPS using [nginx-ingress](https://github.com/kubernetes/charts/tree/master/stable/nginx-ingress), NodePort, ALB, ACM and Route53.
- Bootstrap a cluster by the script.
- Manage the cluster using `kubectl`, `helmfile`, `kops` and `terraform`.


## Build a new cluster

### 1. Setup your environment

Make sure you have the following items:

- An AWS account
- An IAM user with [these permissions](https://github.com/kubernetes/kops/blob/master/docs/aws.md)
- A domain or subdomain, e.g. `dev.example.com`

Install the following tools:

```sh
brew install awscli kubectl kops terraform helm helmfile
```

Change the file [`01-env.sh`](01-env.sh) with your environment values.
If you do not want to save the environment values to your Git repository, you can put your values into the file `.env` instead.

Load the values:

```sh
source 01-env.sh
```

Configure your AWS credentials:

```sh
aws configure --profile "$AWS_PROFILE"
```

Generate a key pair to connect to EC2 instances:

```sh
ssh-keygen -f .sshkey -N ''
```


### 2. Create base components

#### 2-1. Route53

Create a public hosted zone for the domain:

```sh
aws route53 create-hosted-zone --name "$kubernetes_ingress_domain" --caller-reference "$(date)"
```

You may need to add the NS records to the parent zone.


#### 2-2. ACM

Request a certificate for the wildcard domain:

```sh
aws acm request-certificate --domain-name "*.$kubernetes_ingress_domain" --validation-method DNS
```

You need to approve the DNS validation.
Open https://console.aws.amazon.com/acm/home and click the "Create record in Route53" button.
See [AWS User Guide](https://docs.aws.amazon.com/acm/latest/userguide/gs-acm-validate-dns.html) for more.


#### 2-3. S3

Create a bucket for the state store of kops and Terraform.
You must enable bucket versioning.

```sh
aws s3api create-bucket \
  --bucket "$state_store_bucket_name" \
  --region "$AWS_DEFAULT_REGION" \
  --create-bucket-configuration "LocationConstraint=$AWS_DEFAULT_REGION"
aws s3api put-bucket-versioning \
  --bucket "$state_store_bucket_name" \
  --versioning-configuration "Status=Enabled"
```

Initialize the state store of Terraform.

```sh
terraform init -backend-config="bucket=$state_store_bucket_name"
```


### 3. Create a cluster

Create a cluster configuration:

```sh
kops create cluster \
  --name "$KOPS_CLUSTER_NAME" \
  --zones "${AWS_DEFAULT_REGION}a,${AWS_DEFAULT_REGION}c" \
  --ssh-public-key .sshkey.pub

# recreate the instance group for single AZ
kops create instancegroup "nodes-${AWS_DEFAULT_REGION}a" --name "$KOPS_CLUSTER_NAME" --subnet "${AWS_DEFAULT_REGION}a" --edit=false
kops delete instancegroup nodes --name "$KOPS_CLUSTER_NAME" --yes
```

You can change the configuration:

```sh
kops edit cluster
kops edit instancegroup "master-${AWS_DEFAULT_REGION}a"
kops edit instancegroup "nodes-${AWS_DEFAULT_REGION}a"
```

Finally create actual resources for the cluster:

```sh
kops update cluster --yes
```

#### Minimum instance type and volume size

Here is an example of minimum size.
You can use spot instances of `m3.medium`.
As well as you can reduce size of root volumes.
This is not for production.

```yaml
# kops edit cluster
spec:
  etcdClusters:
  - etcdMembers:
    - instanceGroup: master-us-west-2a
      name: a
      volumeSize: 1
    name: main
  - etcdMembers:
    - instanceGroup: master-us-west-2a
      name: a
      volumeSize: 1
    name: events
```

```yaml
# kops edit instancegroup
spec:
  machineType: m3.medium
  maxPrice: "0.02"
  rootVolumeSize: 10
```


### 4. Create additional components

Run the script:

```sh
./02-bootstrap.sh
```

By default the script will create the following components:

- Terraform
  - An internet-facing ALB
  - A Route53 record for the internet-facing ALB
  - A security group for the internet-facing ALB
  - An EFS filesystem for Persistent Volumes
- kubectl
  - Create `ServiceAccount` and `ClusterRoleBinding` for the Helm tiller
  - Patch `StorageClass/gp2` to remove the default storage class
- Helm
  - [`stable/nginx-ingress`](https://github.com/kubernetes/charts/tree/master/stable/nginx-ingress)
  - [`stable/kubernetes-dashboard`](https://github.com/kubernetes/charts/tree/master/stable/kubernetes-dashboard)
  - [`int128.github.io/kubernetes-dashboard-proxy`](https://github.com/int128/kubernetes-dashboard-proxy)
  - [`stable/heapster`](https://github.com/kubernetes/charts/tree/master/stable/heapster)
  - [`stable/efs-provisioner`](https://github.com/helm/charts/tree/master/stable/efs-provisioner)


## Manage the cluster

### Operation

Tell the following steps to your team members.

Onboarding:

```sh
source 01-env.sh

# Configure your AWS credentials.
aws configure --profile "$AWS_PROFILE"

# Initialize kubectl and Terraform.
./10-init.sh
```

Daily operation:

```sh
source 01-env.sh

# Now you can execute the following tools.
kops
terraform
helmfile
```

### Customizing

#### Restrict access to Kubernetes API and SSH

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


#### Restrict access to internet-facing ALB

The following resources are needed so that the masters and nodes can access to services in the VPC:

- An internal ALB
- A Route53 private hosted zone for the internal ALB
- A Route53 record for the internal ALB
- A security group for the internal ALB

To change access control for the internet-facing ALB, edit `tf_config.tf`:

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


#### OIDC authentication

See [extras/oidc](extras/oidc).


#### Working with managed services

Terraform creates the security group `allow-from-nodes.hello.k8s.local` which allows access from the Kubernetes nodes.
You can attach the security group to managed services such as RDS or Elasticsearch.

See also [tf_managed_services.tf](tf_managed_services.tf).


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
Managed | EFS | General Purpose up to 5GB | free
Managed | RDS | t2.micro gp2 20GB | free

The cluster name must be a domain name in order to reduce an ELB for masters.

```sh
# 01-env.sh
kubernetes_cluster_name=dev.example.com
```


## Contribution

This is an open source software licensed under Apache License 2.0.
Feel free to bring up issues or pull requests.
