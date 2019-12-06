# Nexus Terraform

This project deploy a full Kubernetes infrastructure based on AWS Cloud Platform (EKS) and host the Nuxeo Nexus Central container (https://github.com/nuxeo/docker-nexus3).

* The `modules` folder organize the infrastructure code as layer
* `test` and `prod` folder are used to isolate environment specific configurations

## Requirements

See <https://nuxeowiki.atlassian.net/wiki/spaces/DVT/pages/870547484/Coding>

- Python 3
- pip 3
- AWS CLI 1.16+
- Okta-AWS integration tool
- Terraform 0.12+
- Kubectl

Below are suggested installs. Choose the one matching your environment and preferences.

### Python 3, pip 3

```bash
curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py | python3 --user
```

### Terraform

<https://www.terraform.io/downloads.html>

## Configuration

### Kubectl (by AWS)

```bash
$ unset KUBECONFIG
$ aws eks list-clusters
$ aws eks update-kubeconfig --name terraform-eks-nexus-central

$ kubectl get nodes
NAME                                      STATUS   ROLES    AGE   VERSION
```

### Kubectl (by Terraform)

See the [Kubeconfig](#Kubeconfig) section.

### Terraform

**Shell completion** can be installed either with one time command `terraform -install-autocomplete` or with `complete -C terraform terraform` added in your _~/.bashrc_ 

## Usage

### Getting Started

Repeat [Get Credentials](#Get-Credentials) steps.

Browse to the wanted folder `prod`, `test`...

```bash
cd tf/nexus/prod
terraform init
```

Then check changes before applying context

```bash
terraform plan
```

Finally execute Terraform to apply current state to the infrastructure

```bash
terraform apply
```

### Outputs

The Terraform script will output some content to be saved in file for kubernetes access

Currently thoses outputs are defined:

- config-map-aws.yaml
- kubeconfig.yaml

#### Kubeconfig

Please follow this to set your Kubernetes cluster access
```bash
# Save kubeconfig output in a local parameter file to configure your kubectl client
terraform output kubeconfig > kubeconfig.yaml

#Set your current Kubeconfig parameter file
export KUBECONFIG=./kubeconfig.yaml

#Set the default namespace you want to work with. 
kubectl config set-context --current --namespace=devops-tools-test
```

Then follow here with some command to browse the cluster resources
```bash
kubectl cluster-info
kubectl get nodes --all-namespaces
kubectl get pods --all-namespaces
kubectl get pods -n devops-tools-test #for a specific namespace
```

#### config-map-aws.yaml

```bash
# Generate the AWS configmap
terraform output config-map-aws |tee config-map-aws.yaml

# Apply configmap on Kubernetes cluster
kubectl apply -f config-map-aws.yaml
```

#### Datadog Monitoring

The stack defined in [modules/03_monitoring](modules/03_monitoring) includes :

- The `kube-state-metrics` which role is to generate cluster state metrics and expose them to the metrics API.
- The `Cluster Agent` which role is to act as a proxy between the API servers and the rest of the node-based agents.
- The `Datadog Agent` which role is to collect and forward metrics, logs and traces from the cluster nodes and the containers they're running.

Doc: <https://www.datadoghq.com/blog/eks-monitoring-datadog/#deploy-the-agent-to-your-eks-cluster>  
Monitor: <https://app.datadoghq.com/monitors/10694977>  
Dashboard: <https://app.datadoghq.com/screen/integration/86/kubernetes---overview>  

## Use Cases

### Create PROD

```bash
terraform init
terraform plan -no-color | tee tfplan
# Chicken&egg issue: after cluster creation, you must update the refs in kubeconfig.yaml
terraform plan -no-color | tee tfplan
terraform apply -no-color | tee tfplan
```

### Destroy Test Environment
First plan to destroy environment

    terraform plan -destroy -out tfdestroy

Then apply destruction based on state planed 

    terraform -destroy tfdestroy

### Update Test Environment

terraform plan
terraform apply

### Changes Pull Request

TODO

<https://learn.hashicorp.com/terraform/development/running-terraform-in-automation>

```bash
TF_IN_AUTOMATION=true

# Initialize the Terraform working directory.
terraform init -input=false

# Produce a plan for changing resources to match the current configuration.
terraform plan -out=tfplan -input=false

# Have a human operator review that plan, to ensure it is acceptable.
terraform plan -input=false

# Apply the changes described by the plan.
terraform apply -input=false tfplan

# See also:
TF_WORKSPACE=
terraform workspace select
```

## Troubleshooting

<https://docs.aws.amazon.com/fr_fr/eks/latest/userguide/network_reqs.html>

### DEBUG

`TF_LOG=TRACE`

### Kubectl returns `No resources found.`

Problem: I have applied the terraform infrastructure, the EC2 instance looks ready but kubectl returns no node resource:

```bash
$ kubectl get nodes --all-namespaces
No resources found.
```

Solution: apply the AWS configmap.

```bash
$ kubectl apply -f config-map-aws.yaml
configmap/aws-auth created
```

Then the nodes are authorized to join EKS master node

```bash
$ kubectl get nodes --all-namespaces
```

## Resources

<https://bcouetil.gitlab.io/academy/BP-kubernetes.html#terraform-installation>
<https://kubernetes.io/docs/reference/kubectl/cheatsheet/>
<https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands>
<https://nuxeowiki.atlassian.net/wiki/spaces/DVT/pages/814514263/AWS>
<https://nuxeowiki.atlassian.net/wiki/spaces/SEC/pages/2721564/Use+AWS+CLI+with+Okta>


# How to develop

```bash
cd tf/nexus/test
git co feature-NXBT0123
terraform workspace create feature-NXBT0123

terraform plan -out tfplan
terraform show tfplan # for a short list of modified resources
terraform apply tfplan
```

At this time infrastructure is deploying and stop until aws config map is deployed and nodes IP are allowed to fetch dockerpriv repository

Retrieve new nodes IP and authorize to access

    kubectl get nodes -o jsonpath='{.items[*].status.addresses[?(@.type=="ExternalIP")].address}'

Remove all containers and restart
* kubectl delete pods terraform-eks-nexus-central-test-pod-{0,1,2}

Gain your pods IP addresses

    kubectl get pods -o jsonpath='{.items[*].status.podIP}'


## How to recovery blob store index from a totally new installation

Create manual task and execute:  

* `Repair - Reconcile component database from blob store`

And because of npm and yum browsing needs more task to be recovered [Nexus SystemConfiguration - TypesofTasksandWhentoUseThem](https://help.sonatype.com/repomanager3/configuration/system-configuration#SystemConfiguration-TypesofTasksandWhentoUseThem)

* `Repair - Rebuild repository browse`
* `Repair - Rebuild repository search`

# How to debug

Execute an interactive bash in the container
* kubectl exec -it terraform-eks-nexus-central-test-pod-0 bash

