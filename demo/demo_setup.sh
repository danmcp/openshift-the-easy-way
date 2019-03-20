#!/usr/bin/env bash

# pre reqs: Login to a cluster with oc

#oc get operatorsources certified-operators -n openshift-marketplace -o yaml

# Increase default size of the cluster
#oc get machinesets -n openshift-machine-api
machine_set_id=`oc get machinesets -n openshift-machine-api | sed '2q;d' | cut -d'-' -f2`
oc patch machineset/rhsummit2019-${machine_set_id}-worker-us-east-1a -n openshift-machine-api --type=json --patch '[{"op": "replace", "path": "/spec/replicas", "value":3}]'
oc patch machineset/rhsummit2019-${machine_set_id}-worker-us-east-1b -n openshift-machine-api --type=json --patch '[{"op": "replace", "path": "/spec/replicas", "value":3}]'
oc patch machineset/rhsummit2019-${machine_set_id}-worker-us-east-1c -n openshift-machine-api --type=json --patch '[{"op": "replace", "path": "/spec/replicas", "value":3}]'

# Create extra operator sources
oc create -f assets/operator-sources1.yaml

oc new-project myproject
oc adm policy add-role-to-user admin jessica -n myproject

# Create projects
for i in `seq 96 100`;
do
  if [ $i -lt 10 ]
  then
    project_name=project00${i}
  elif [ $i -lt 100 ]
  then
    project_name=project0${i}
  else
    project_name=project${i}
  fi
  oc new-project $project_name
  oc adm policy add-role-to-user admin jessica -n $project_name

  oc create -f - <<EOF
apiVersion: v1
kind: LimitRange
metadata:
  name: mem-limit-range
  namespace: $project_name
spec:
  limits:
    - default:
        memory: 4096Mi
      defaultRequest:
        memory: 512Mi
      type: Container
EOF

done

# Subscribe to needed operators
