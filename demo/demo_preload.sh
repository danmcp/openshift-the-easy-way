#!/usr/bin/env bash

# Create a CR in the first X projects
for i in `seq 1 5`;
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

# Create extra stuff in the first X projects
for i in `seq 1 5`;
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
  oc new-app nodejs~https://github.com/danmcp/nodejs-frontend.git -n $project_name --name="nodejs"
  oc expose service/nodejs -n $project_name
  oc new-app registry.access.redhat.com/jboss-webserver-3/webserver31-tomcat8-openshift~https://github.com/openshift/openshift-jee-sample.git -n $project_name --name="jbosswebserver"
  oc expose service/jbosswebserver -n $project_name
done