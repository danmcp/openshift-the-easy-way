#!/usr/bin/env bash

# Create a CR in the last 10 projects
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

  oc create -f - <<EOF
apiVersion: sqlserver.microsoft.com/v1beta2
kind: SQLServerCluster
metadata:
  name: ${project_name}-sqlserver
  annotations:
    sqlserver.microsoft.com/scope: clusterwide
  namespace: ${project_name}
spec:
  size: 3
  version: 14.0.1
EOF

done


# Create extra stuff in last 10 projects
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

  oc process jenkins-ephemeral -n openshift | oc create -n $project_name -f -
  oc new-app nodejs~https://github.com/sclorg/nodejs-ex.git -n $project_name --name="nodejs"
  oc expose service/nodejs -n $project_name
  oc new-app registry.access.redhat.com/jboss-webserver-3/webserver31-tomcat8-openshift~https://github.com/openshift/openshift-jee-sample.git -n $project_name --name="jbosswebserver"
  oc expose service/jbosswebserver -n $project_name
done

oc apply -f assets/operator-sources2.yaml


machine_set_id=`oc get machinesets -n openshift-machine-api | sed '2q;d' | cut -d'-' -f2`
oc patch machineset/rhsummit2019-${machine_set_id}-worker-us-east-1a -n openshift-machine-api --type=json --patch '[{"op": "replace", "path": "/spec/replicas", "value":4}]'
oc patch machineset/rhsummit2019-${machine_set_id}-worker-us-east-1b -n openshift-machine-api --type=json --patch '[{"op": "replace", "path": "/spec/replicas", "value":4}]'
oc patch machineset/rhsummit2019-${machine_set_id}-worker-us-east-1c -n openshift-machine-api --type=json --patch '[{"op": "replace", "path": "/spec/replicas", "value":4}]'