# OpenShift Demo

## Part 1 - Day 1 Install

### Quick Install

- designed to help users from novice to expert
- create clusters in various environments
- default act as install wizard
- advanced users have areas to customize
- provisions underlying infrastructure
- bootstraps cluster using generated assets

```sh
#export AWS_PROFILE=openshift-dev
export OPENSHIFT_INSTALL_PULL_SECRET_PATH=/home/dmcphers/Downloads/config.json
openshift-install --help
openshift-install create --help
openshift-install create cluster
```

**Prompts**
- id_rsa.pub
- base domain: rhsummit2019.com
- cluster-name: rhsummit2019
- aws
- us-east-1

1. bootstrap machine boots and starts hosting the remote resources required for
   the master machines to boot.
2. master machines fetch ignition resources from the bootstrap machine and
   finish booting.
3. master machines use the bootstrap node to form an etcd cluster.
4. bootstrap node starts a temporary Kubernetes control plane using the
   newly-created etcd cluster.
5. temporary control plane schedules the production control plane to the master
   machines.
6. temporary control plane shuts down, yielding to the production control plane.
7. bootstrap node injects OpenShift-specific components into the newly formed
   control plane.
8. installer then tears down the bootstrap node.

- cluster is now self-automated
- creates its own worker machines using cluster-api

## Part 2: Day 2 (Operating the cluster)

### Setup

Setup the cluster to enable updates (temp)
```sh
oc patch clusterversion/version --patch '{"spec":{"upstream":"https://origin-release.svc.ci.openshift.org/graph"}}' --type=merge
```


### Operators

- method of packaging, deploying and managing a Kubernetes application that is
  both deployed on Kubernetes and managed using the Kubernetes APIs.
- Kubernetes does a great job managing, so why not manage Kube itself?
- `ClusterVersionOperator` that manages a set of operators to install, update,
  and lifecycle Kubernetes itself.
- operators allow us to manage the core control plane components as a Kubernetes
  native application
- the `ClusterVersionOperator` manages a minimal set of components required to
  bring up an OpenShift service.

```sh
# cluster version reports the version of the cluster
# it also tracks how it gets updates to new versions over time
oc get clusterversion
# to see more detail about the cluster version, describe it
oc describe clusterversion
# the release payload is an image that maps components to operators at a version
# to see the list of operators that define a version we can expect the image
oc adm release info registry.svc.ci.openshift.org/openshift/origin-release:v4.0
# we can see the source and commits
oc adm release info registry.svc.ci.openshift.org/openshift/origin-release:v4.0 --commits
# the cluster version operator applies a version to a cluster
# the resources it applies are just kubernetes artifacts
oc get deployments -n openshift-cluster-version
# you can see in the logs, it just applies the desired changes
# and the cluster converges forward
oc logs deployments/cluster-version-operator -n openshift-cluster-version
```

- an upgrade applying new image for the cluster version operator to rollout.
- that payload image could include a control plane, node, or OS update.
- lets look at the operators
- the control plane needs to be rock solid
- having operators for the core control plane always reconciling and converging

- each operator syncs out for cluster version operator to read

```sh
oc get clusteroperators
```

- the core control plane operators are configured via kube APIs
- each operator reads a desired state from a crd, and converges
- always reconciles, its level driven
- you go from fire/forget upgrade, to always ensuring we converge

```sh
oc get customresourcedefinitions
oc get crds | grep config.openshift.io
```

- the administration interface for OpenShift becomes Kubernetes itself.
- operators to manage storage, routing, sdn, node tuning, machine config, etc.

### Machine Configuration

- machine config operator is responsible for configuring hosts
- the operator installs a controller, machine daemon, and server (for ignition)
- machine config resources describe assets that should go on machine based on role
- each config defines a rendering for a list of files
- configs are grouped together in pools
- the controller coordinates with the daemon by asserting a desired config
- config changes are rolled out one node at a time
- machine is drained, updates are made, and its rebooted


```sh
oc get deployments -n openshift-machine-config-operator machine-config-operator
oc get machineconfigs
oc get machineconfig -o yaml | less
oc get machineconfigs -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{range
.spec.config.storage.files[*]}{"\t"}{.filesystem}{"\t"}{.path}{"\n"}{end}{"\n"}{end}{"\n"}'
| less
oc get machineconfigpools 
oc get nodes -o yaml | grep annotations -A 3
```

## Part 3 - Compute

- adopting the machine API from kubernetes-sigs/cluster-api
- machine is base atom of compute (i.e. like pod)

```sh
oc get machines -n openshift-cluster-api
```

- provider specific section for each cloud

```sh
oc get machines -n openshift-cluster-api -o yaml
```

- machinesets are like replicasets for machines

```sh
oc get machinesets -n openshift-cluster-api
```

- to provision or deprovision a machine just requires deleting the resource

```sh
# to find all masters
oc get machines -l sigs.k8s.io/cluster-api-machine-type=master -n 
# by default the installer spreads machines across zones for HA
oc get machines -l sigs.k8s.io/cluster-api-machine-type=master -n
openshift-cluster-api -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.providerConfig.value.placement.availabilityZone}{"\n"}{end}'
# to find all workers
oc get machines -l sigs.k8s.io/cluster-api-machine-type=worker -n openshift-cluster-api
# by default the installer spreads workers across zones for HA
oc get machinesets -n openshift-cluster-api -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.replicas}{"\n"}{end}'
# cluster autoscaler adds and removes machines from a cluster to meet demand
# openshift has an operator for the autoscaler, let's deploy the autoscaler
oc create -f ../openshift-the-easy-way/assets/cluster-autoscaler.yaml
# note the autoscaler is running
oc get deployments cluster-autoscaler-default -n openshift-cluster-api
```

- lets scale each worker set between 1 and 12 machines using a MachineAutoscaler

```sh
oc create -f ../openshift-the-easy-way/assets/machine-autoscale-us-east-1a.yaml
oc create -f ../openshift-the-easy-way/assets/machine-autoscale-us-east-1b.yaml
oc create -f ../openshift-the-easy-way/assets/machine-autoscale-us-east-1c.yaml
```

- lets verify the annotations were applied as expected

```sh
oc get machinesets -n openshift-cluster-api -o yaml | grep -A 2 annotations
```

- lets introduce a workload that requires more machines

```sh
oc new-project work-queue
oc create -f ../openshift-the-easy-way/assets/job-work-queue.yaml
```

- this will create a lot of pods that need scheduling
- to schedule these pods, we need more machines

```sh
oc get machines -n openshift-cluster-api
# new machines take ~3m to provision and get a ready node
oc get nodes -w
```

- show monitoring ui while we wait
- exploring other tools around machine api including health checking and fencing

### Part 4 - Cleanup

- as you can see, openshift v4 brings everything under management of the cluster
- operators, operating system, and infrastructure

```sh
openshift-install destroy cluster
```