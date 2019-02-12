### Operators

oc rsh -n openshift-cluster-version deployments/cluster-version-operator
ls release-manifests

```sh
oc get deployments --all-namespaces | grep openshift-cluster-kube
```

- openshift team has worked hard in past 2 years to improve API machinery
- v4 lets us clearly delineate kubernetes and openshift api servers

```sh
oc get pods -n openshift-kube-apiserver
oc get pods -n openshift-kube-scheduler
oc get pods -n openshift-kube-controller-manager
```

- what is really cool about these operators is they manage static pods

```sh
oc get ds -n openshift-apiserver
oc get ds -n openshift-controller-manager
```



### Red Hat CoreOS (5m)

- each node in the cluster is running red hat coreos

```sh
oc get nodes -o wide
oc get nodes -l node-role.kubernetes.io/master -o wide
export EXTERNAL_IP=<EXTERNAL IP>
PEM_FILE=~/.ssh/libra.pem
ssh -i $PEM_FILE core@$EXTERNAL_IP
```

- its rhel kernel and content

```sh
uname -rs
```

- ignition runs at first boot, applies config

```sh
journalctl --no-pager | grep "Ignition finished successful" -B 100
```

- show ready only /usr

```sh
touch /usr/evil
```

- show writable /var

```sh
touch /var/ok
```

- selinux enforcing

```sh
sestatus
```

- kubelet on host

```sh
systemctl status kubelet -l
```

- crio

```sh
systemctl status crio -l
```

- crictl

```sh
sudo crictl pods
```

- podman (bootstrap node only)

```sh
sudo podman ps
```

### Patterns for customer / isv
- olm
- daemonless build

```sh
oc new-project my-app
oc new-app centos/ruby-25-centos7~https://github.com/sclorg/ruby-ex.git
oc logs -f bc/ruby-ex
oc expose svc/ruby-ex
oc get routes ruby-ex -o jsonpath='{"http://"}{.spec.host}{"/"}{"\n"}'
https://ruby-ex-my-app.apps.example.com/
```