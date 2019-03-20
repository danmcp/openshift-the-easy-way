#!/usr/bin/env bash

# pre reqs: Login to a cluster with oc

#oc patch clusterversion/version --patch '{"spec":{"upstream":"https://origin-release.svc.ci.openshift.org/graph"}}' --type=merge

machine_set_id=`oc get machinesets -n openshift-machine-api | sed '2q;d' | cut -d'-' -f2`
oc delete machineset rhsummit2019-${machine_set_id}-worker-us-east-1d -n openshift-machine-api
oc delete machineset rhsummit2019-${machine_set_id}-worker-us-east-1e -n openshift-machine-api
oc delete machineset rhsummit2019-${machine_set_id}-worker-us-east-1f -n openshift-machine-api

oc create -f ../openshift-the-easy-way/assets/cluster-autoscaler.yaml

oc create -f ../openshift-the-easy-way/assets/machine-autoscale1.yaml
oc create -f ../openshift-the-easy-way/assets/machine-autoscale2.yaml
oc create -f ../openshift-the-easy-way/assets/machine-autoscale3.yaml

# Add jenkins and tomcat to the dev catalog
oc patch is jenkins -n openshift --type=json --patch '[{"op": "replace", "path": "/spec/tags/0/annotations/tags", "value": "jenkins,builder"}]'
oc patch is jboss-webserver31-tomcat8-openshift -n openshift --type=json --patch '[{"op": "replace", "path": "/spec/tags/0/annotations/tags", "value": "builder,tomcat,tomcat8,java,jboss"}]'

#Create users
oc apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: htpass-secret
  namespace: openshift-config
data:
  htpasswd: ZGFuOiRhcHIxJHNxVGF6SmlCJER2QmphZDl3cTJCbTQxQTdNaFdVdzEKamVzc2ljYTokYXByMSQ1Vnh6aGxpSyRwbFhNOGdVQVIzRGJNWlEwWGF3RnMvCg==
EOF

oc apply -f - <<EOF
apiVersion: config.openshift.io/v1
kind: OAuth
metadata:
  name: cluster
spec:
  identityProviders:
  - name: htpassidp
    challenge: true
    login: true
    mappingMethod: claim
    type: HTPasswd
    htpasswd:
      fileData:
        name: htpass-secret
EOF

oc adm policy add-cluster-role-to-user cluster-admin dan

# Create projects
for i in `seq 1 95`;
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
